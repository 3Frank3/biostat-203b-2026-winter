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
                     choices = c("Histogram", "Boxplot", "Barplot"))
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
        h4("Admissions"),
        DTOutput("admission_table"),
        h4("ADT / Transfers"),
        DTOutput("adt_table"),
        h4("ICU stays"),
        DTOutput("icu_table")
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
  
  # 假設你已經有 con_bq
  admission_info <- eventReactive(input$go_patient, {
    tbl(con_bq, "admissions") |>
      filter(subject_id == input$subject_id) |>
      collect()
  })
  
  adt_info <- eventReactive(input$go_patient, {
    tbl(con_bq, "transfers") |>
      filter(subject_id == input$subject_id) |>
      arrange(intime) |>
      collect()
  })
  
  icu_info <- eventReactive(input$go_patient, {
    tbl(con_bq, "icustays") |>
      filter(subject_id == input$subject_id) |>
      collect()
  })
  
  output$admission_table <- renderDT({
    admission_info()
  })
  
  output$adt_table <- renderDT({
    adt_info()
  })
  
  output$icu_table <- renderDT({
    icu_info()
  })
}

shinyApp(ui, server)