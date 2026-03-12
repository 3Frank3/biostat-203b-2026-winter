library(shiny)
library(tidyverse)
library(bigrquery)
library(DT)
library(gtsummary)
library(DBI)
library(bigrquery)
library(dbplyr)

# path to the service account token 
satoken <- "biostat-203b-2026-winter-92fefbfab477.json"
# BigQuery authentication using service account
bq_auth(path = satoken)

con_bq <- dbConnect(
    bigrquery::bigquery(),
    project = "biostat-203b-2025-winter",
    dataset = "mimiciv_3_1",
    billing = "biostat-203b-2025-winter"
)
con_bq

patients_tbl      <- tbl(con_bq, "patients")
admissions_tbl    <- tbl(con_bq, "admissions")
transfers_tbl     <- tbl(con_bq, "transfers")
diag_tbl          <- tbl(con_bq, "diagnoses_icd")
d_diag_tbl        <- tbl(con_bq, "d_icd_diagnoses")
proc_tbl          <- tbl(con_bq, "procedures_icd")
d_proc_tbl        <- tbl(con_bq, "d_icd_procedures")

icustays_tbl      <- tbl(con_bq, "icustays")
labevents_tbl     <- tbl(con_bq, "labevents")
chartevents_tbl   <- tbl(con_bq, "chartevents")
d_items_tbl       <- tbl(con_bq, "d_items")

cohort <- readr::read_rds("mimic_icu_cohort.rds")

demo_vars <- c("race", "insurance", "marital_status", "gender", "age_intime")
lab_vars <- c("Bicarbonate", "Creatinine", "Potassium", "Sodium",
              "Chloride", "Hematocrit", "Hemoglobin", "Platelet_Count", "Glucose")
vital_vars <- c("heart_rate", "sbp", "dbp", "temperature_c", "resp_rate")

ui <- navbarPage(
  "MIMIC-IV ICU Explorer",
  
  tabPanel(
    "Cohort Explorer",
    sidebarLayout(
      sidebarPanel(
        selectInput("domain", "Choose variable group:",
                    choices = c("Demographics", "Labs", "Vitals")),
        uiOutput("var_select"),
        checkboxInput("group_los", "Stratify by los_long", value = FALSE),
        radioButtons("plot_type", "Plot type:",
                     choices = c("Histogram", "Boxplot"))
      ),
      mainPanel(
        tableOutput("summary_table"),
        plotOutput("var_plot"),
        DTOutput("data_preview")
      )
    )
  ),
  
  tabPanel(
  "Patient Explorer",
  sidebarLayout(
    sidebarPanel(
      numericInput("subject_id", "Enter subject_id:", value = 10000032),
      actionButton("go_patient", "Query patient")
    ),
    mainPanel(
      h4("ADT / Procedure / Lab Timeline"),
      plotOutput("adt_timeline_plot", height = "500px"),
      
      br(),
      h4("Vitals Over Time"),
      plotOutput("vitals_plot", height = "600px"),
      
     )
   )
 )
)

server <- function(input, output, session) {
  
  output$var_select <- renderUI({
    vars <- switch(input$domain,
                   "Demographics" = demo_vars,
                   "Labs" = lab_vars,
                   "Vitals" = vital_vars)
    selectInput("varname", "Choose variable:", choices = vars)
  })
  
  output$summary_table <- renderTable({
    req(input$varname)
    dat <- cohort
    v <- dat[[input$varname]]
    
    if (is.numeric(v)) {
      tibble(
        Variable = input$varname,
        N = sum(!is.na(v)),
        Mean = mean(v, na.rm = TRUE),
        SD = sd(v, na.rm = TRUE),
        Median = median(v, na.rm = TRUE),
        Min = min(v, na.rm = TRUE),
        Max = max(v, na.rm = TRUE)
      )
    } else {
      dat |>
        count(.data[[input$varname]], sort = TRUE)
    }
  })
  
  output$var_plot <- renderPlot({
    req(input$varname, input$plot_type)
    dat <- cohort
    v <- input$varname
    
    if (is.numeric(dat[[v]])) {
      if (input$plot_type == "Histogram") {
        ggplot(dat, aes(x = .data[[v]])) +
          geom_histogram(bins = 30) +
          labs(x = v, y = "Count")
      } else {
        if (input$group_los) {
          ggplot(dat, aes(x = as.factor(los_long), y = .data[[v]])) +
            geom_boxplot() +
            labs(x = "los_long", y = v)
        } else {
          ggplot(dat, aes(y = .data[[v]])) +
            geom_boxplot() +
            labs(y = v)
        }
      }
    } else {
      if (input$group_los) {
        ggplot(dat, aes(x = .data[[v]], fill = as.factor(los_long))) +
          geom_bar(position = "dodge") +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      } else {
        ggplot(dat, aes(x = .data[[v]])) +
          geom_bar() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))
      }
    }
  })
  
  output$data_preview <- renderDT({
    req(input$varname)
    cohort |>
      select(any_of(c("subject_id", "stay_id", "los_long", input$varname))) |>
      head(20)
  })
  
  patient_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  patients_tbl |>
    filter(subject_id == input$subject_id) |>
    collect()
})
  
  admission_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  admissions_tbl |>
    filter(subject_id == input$subject_id) |>
    arrange(admittime) |>
    collect()
})
  
  transfer_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  transfers_tbl |>
    filter(subject_id == input$subject_id) |>
    arrange(intime) |>
    collect()
})
  
  icu_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  icustays_tbl |>
    filter(subject_id == input$subject_id) |>
    arrange(intime) |>
    collect()
})
  
diag_patient_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  hadm_ids <- admission_tbl()$hadm_id
  
  diag_tbl |>
    filter(hadm_id %in% hadm_ids) |>
    collect()
})

  diag_with_title_tbl <- reactive({
  req(diag_patient_tbl())
  
  diag_local <- diag_patient_tbl()
  d_diag_local <- d_diag_tbl |>
    collect()
  
  diag_local |>
    left_join(d_diag_local, by = c("icd_code", "icd_version"))
})
  
  proc_patient_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  hadm_ids <- admission_tbl()$hadm_id
  
  proc_tbl |>
    filter(hadm_id %in% hadm_ids) |>
    collect()
})
  
  proc_with_title_tbl <- reactive({
  req(proc_patient_tbl())
  
  d_proc_local <- d_proc_tbl |>
    collect()
  
  proc_patient_tbl() |>
    left_join(d_proc_local, by = c("icd_code", "icd_version"))
})
  
  labs_timeline_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  hadm_ids <- admission_tbl()$hadm_id
  
  labevents_tbl |>
    filter(hadm_id %in% hadm_ids) |>
    select(subject_id, hadm_id, charttime, itemid) |>
    filter(!is.na(charttime)) |>
    collect()
})
  
  vital_items <- c(220045, 220179, 220180, 223761, 220210)

vitals_tbl <- eventReactive(input$go_patient, {
  req(input$subject_id)
  
  chartevents_tbl |>
    filter(subject_id == input$subject_id) |>
    filter(itemid %in% vital_items) |>
    select(subject_id, stay_id, charttime, itemid, valuenum) |>
    filter(!is.na(charttime), !is.na(valuenum)) |>
    collect()
})

vitals_labeled_tbl <- reactive({
  req(vitals_tbl())
  
  d_items_local <- d_items_tbl |>
    filter(itemid %in% vital_items) |>
    select(itemid, label, abbreviation) |>
    collect()
  
  vitals_tbl() |>
    left_join(d_items_local, by = "itemid")
})

patient_info_text <- reactive({
  req(patient_tbl(), admission_tbl())
  
  patient <- patient_tbl()
  admissions <- admission_tbl()
  
  patient_race <- admissions |>
    distinct(race) |>
    pull(race) |>
    first()
  
  paste0(
    "Patient ", patient$subject_id[1], ", ",
    patient$gender[1], ", ",
    patient$anchor_age[1], " years old, ",
    tolower(patient_race)
  )
})

top_3_diag_text <- reactive({
  req(diag_with_title_tbl())
  
  diag_with_title_tbl() |>
    slice_head(n = 3) |>
    pull(long_title) |>
    paste(collapse = "\n")
})

adt_plot_data <- reactive({
  req(transfer_tbl())
  
  y_levels <- c("Procedure", "Lab", "ADT")
  
  transfer_tbl() |>
    filter(!is.na(careunit)) |>
    mutate(
      line_weight = if_else(str_detect(careunit, "ICU|CCU"), 5, 1.5),
      y_label = factor("ADT", levels = y_levels)
    )
})

lab_plot_data <- reactive({
  req(labs_timeline_tbl())
  
  y_levels <- c("Procedure", "Lab", "ADT")
  
  labs_timeline_tbl() |>
    mutate(
      y_label = factor("Lab", levels = y_levels)
    )
})

proc_plot_data <- reactive({
  req(proc_with_title_tbl())
  
  y_levels <- c("Procedure", "Lab", "ADT")
  
  proc_with_title_tbl() |>
    filter(!is.na(chartdate)) |>
    mutate(
      y_label = factor("Procedure", levels = y_levels),
      long_title_wrapped = stringr::str_wrap(long_title, width = 30)
    )
})

output$adt_timeline_plot <- renderPlot({
  req(adt_plot_data(), lab_plot_data(), proc_plot_data())
  
  ggplot() +
    geom_segment(
      data = adt_plot_data(),
      aes(
        x = intime, xend = outtime,
        y = y_label, yend = y_label,
        color = careunit,
        size = line_weight
      )
    ) +
    geom_point(
      data = proc_plot_data(),
      aes(
        x = chartdate,
        y = y_label,
        shape = long_title_wrapped
      ),
      size = 3
    ) +
    geom_point(
      data = lab_plot_data(),
      aes(
        x = charttime,
        y = y_label
      ),
      shape = 3
    ) +
    scale_size_identity() +
    labs(
      title = patient_info_text(),
      subtitle = top_3_diag_text(),
      x = "Calendar Time",
      y = NULL,
      color = "Care Unit",
      shape = "Procedure"
    ) +
    theme_minimal() +
    theme(
      legend.position = "bottom",
      legend.box = "vertical",
      legend.text = element_text(size = 8),
      panel.grid.minor = element_blank(),
      axis.text.y = element_text(face = "bold", size = 10)
    ) +
    scale_y_discrete(drop = FALSE) +
    guides(shape = guide_legend(ncol = 2, byrow = TRUE))
})

output$vitals_plot <- renderPlot({
  req(vitals_labeled_tbl())
  
  ggplot(
    vitals_labeled_tbl(),
    aes(x = charttime, y = valuenum, color = label)
  ) +
    geom_line() +
    geom_point(size = 1) +
    facet_grid(abbreviation ~ stay_id, scales = "free") +
    labs(
      x = "Chart Time",
      y = "Value",
      color = "Vital Sign",
      title = paste("Vitals for subject_id =", input$subject_id)
    ) +
    theme_minimal()
})
}

shinyApp(ui, server)