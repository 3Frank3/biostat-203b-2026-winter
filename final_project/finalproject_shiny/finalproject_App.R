# app.R
library(shiny)
library(dplyr)
library(ggplot2)
library(DT)
library(readr)
library(tidymodels)
library(purrr)

# -----------------------
# Load data
# -----------------------
df <- readRDS("final_project_cohort.rds")

# Ensure outcome is factor with levels 0/1
if (!is.factor(df$y_prolong)) {
  df <- df |> mutate(y_prolong = factor(y_prolong, levels = c(0, 1)))
} else {
  # enforce ordering if needed
  df$y_prolong <- factor(df$y_prolong, levels = c("0", "1"))
}

# Optional: make sure IDs are not character if you prefer
# df <- df |> mutate(across(any_of(c("stay_id","subject_id","hadm_id")), as.character))

# -----------------------
# Load models (3 workflows)
# -----------------------
wf_logit <- readRDS("wf_logit.rds")
wf_rf    <- readRDS("wf_rf.rds")
wf_xgb   <- readRDS("wf_xgb.rds")

models <- list(
  "Elastic-net Logistic" = wf_logit,
  "Random Forest"        = wf_rf,
  "XGBoost"              = wf_xgb
)

# -----------------------
# Utilities
# -----------------------
safe_num <- function(x) {
  if (is.null(x)) return(NA_real_)
  suppressWarnings(as.numeric(x))
}

# A small set of default features for manual input (edit freely)
default_manual_features <- intersect(c(
  "anchor_age", "gender",
  "bmi", "sbp", "dbp",
  "UreaNitrogen", "creatinine", "potassium", "sodium",
  "heart_rate", "systolic_bp", "diastolic_bp", "temperature_c", "respiratory_rate"
), names(df))

id_cols <- intersect(c("stay_id", "subject_id", "hadm_id"), names(df))

# -----------------------
# UI
# -----------------------
ui <- fluidPage(
  titlePanel("MIMIC-IV Prolonged Ventilation Shiny App"),
  tabsetPanel(
    # -----------------------
    # Tab 1: Cohort explorer
    # -----------------------
    tabPanel("Cohort explorer",
      sidebarLayout(
        sidebarPanel(
          h4("Filters"),
          if ("anchor_age" %in% names(df)) {
            sliderInput(
              "age_range", "Anchor age",
              min = floor(min(df$anchor_age, na.rm = TRUE)),
              max = ceiling(max(df$anchor_age, na.rm = TRUE)),
              value = c(
                floor(min(df$anchor_age, na.rm = TRUE)),
                ceiling(max(df$anchor_age, na.rm = TRUE))
              )
            )
          },
          if ("gender" %in% names(df)) {
            selectInput(
              "gender_filter", "Gender",
              choices = c("All", sort(unique(df$gender))),
              selected = "All"
            )
          },
          selectInput(
            "ygrp", "Outcome group (y_prolong)",
            choices = c("All", "0", "1"),
            selected = "All"
          ),
          checkboxInput("complete_core", "Require core vitals/labs (non-missing)", value = FALSE),
          hr(),
          helpText("Tip: Requiring complete cases can reduce N a lot.")
        ),
        mainPanel(
          h4("Cohort summary"),
          verbatimTextOutput("cohort_summary"),
          h4("Preview (first 200 rows)"),
          DTOutput("cohort_table")
        )
      )
    ),

    # -----------------------
    # Tab 2: Patient trajectory
    # -----------------------
    tabPanel("Patient trajectory",
      sidebarLayout(
        sidebarPanel(
          h4("Select patient"),
          if ("subject_id" %in% names(df)) {
            selectInput(
              "subj", "subject_id",
              choices = sort(unique(df$subject_id)),
              selected = sort(unique(df$subject_id))[1]
            )
          } else {
            helpText("No subject_id column found in model_tbl.csv")
          },
          uiOutput("stay_picker_ui"),
          hr(),
          h4("Snapshot columns"),
          selectizeInput(
            "snap_cols", "Choose columns to display",
            choices = setdiff(names(df), "y_prolong"),
            selected = default_manual_features,
            multiple = TRUE
          )
        ),
        mainPanel(
          h4("All stays for this subject"),
          DTOutput("patient_stays"),
          h4("Vent hours by stay (if available)"),
          plotOutput("vent_plot", height = "260px"),
          h4("Selected stay snapshot"),
          DTOutput("stay_snapshot")
        )
      )
    ),

    # -----------------------
    # Tab 3: ML App
    # -----------------------
    tabPanel("ML app",
      sidebarLayout(
        sidebarPanel(
          h4("Model selection"),
          selectInput("model_choice", "Choose model", choices = names(models), selected = "XGBoost"),
          sliderInput("thr", "Classification threshold", min = 0.05, max = 0.95, value = 0.50, step = 0.01),
          hr(),

          radioButtons(
            "pred_mode", "Prediction mode",
            choices = c("Use a stay from dataset", "Manual input"),
            selected = "Use a stay from dataset"
          ),

          conditionalPanel(
            condition = "input.pred_mode == 'Use a stay from dataset'",
            if ("stay_id" %in% names(df)) {
              selectizeInput(
                "pred_stay", "Choose stay_id",
                choices = sort(unique(df$stay_id)),
                selected = sort(unique(df$stay_id))[1],
                options = list(placeholder = "Type to search stay_id")
              )
            } else {
              helpText("No stay_id column found in dataset.")
            }
          ),

          conditionalPanel(
            condition = "input.pred_mode == 'Manual input'",
            helpText("Enter values. Leave blank if unknown."),
            # numeric inputs
            if ("anchor_age" %in% names(df)) numericInput("in_age", "anchor_age", value = NA, min = 0, max = 120),
            if ("bmi" %in% names(df)) numericInput("in_bmi", "bmi", value = NA),
            if ("sbp" %in% names(df)) numericInput("in_sbp", "sbp (OMR)", value = NA),
            if ("dbp" %in% names(df)) numericInput("in_dbp", "dbp (OMR)", value = NA),
            if ("UreaNitrogen" %in% names(df)) numericInput("in_bun", "UreaNitrogen", value = NA),
            if ("creatinine" %in% names(df)) numericInput("in_cr", "creatinine", value = NA),
            if ("potassium" %in% names(df)) numericInput("in_k", "potassium", value = NA),
            if ("sodium" %in% names(df)) numericInput("in_na", "sodium", value = NA),
            if ("heart_rate" %in% names(df)) numericInput("in_hr", "heart_rate", value = NA),
            if ("systolic_bp" %in% names(df)) numericInput("in_sbp2", "systolic_bp", value = NA),
            if ("diastolic_bp" %in% names(df)) numericInput("in_dbp2", "diastolic_bp", value = NA),
            if ("temperature_c" %in% names(df)) numericInput("in_temp", "temperature_c", value = NA),
            if ("respiratory_rate" %in% names(df)) numericInput("in_rr", "respiratory_rate", value = NA),

            # categorical inputs
            if ("gender" %in% names(df)) selectInput("in_gender", "gender", choices = sort(unique(df$gender)))
          ),

          actionButton("run_pred", "Predict", class = "btn-primary"),
          hr(),
          verbatimTextOutput("pred_out")
        ),
        mainPanel(
          h4("Prediction input (what the model sees)"),
          DTOutput("pred_input_view"),
          h4("Predicted probabilities (all 3 models)"),
          DTOutput("pred_all_models_tbl"),
          plotOutput("pred_bar", height = "260px")
        )
      )
    )
  )
)

# -----------------------
# Server
# -----------------------
server <- function(input, output, session) {

  # ---- Tab 1: Cohort explorer ----
  cohort_filtered <- reactive({
    x <- df

    if ("anchor_age" %in% names(x)) {
      x <- x |> filter(anchor_age >= input$age_range[1], anchor_age <= input$age_range[2])
    }
    if ("gender" %in% names(x) && input$gender_filter != "All") {
      x <- x |> filter(gender == input$gender_filter)
    }
    if (input$ygrp != "All") {
      x <- x |> filter(as.character(y_prolong) == input$ygrp)
    }

    if (isTRUE(input$complete_core)) {
      core <- intersect(c(
        "heart_rate","systolic_bp","diastolic_bp","temperature_c","respiratory_rate",
        "UreaNitrogen","creatinine","potassium","sodium",
        "bmi","sbp","dbp"
      ), names(x))
      if (length(core) > 0) {
        x <- x |> filter(if_all(all_of(core), ~ !is.na(.x)))
      }
    }
    x
  })

  output$cohort_summary <- renderPrint({
    x <- cohort_filtered()
    list(
      n = nrow(x),
      n_subject = if ("subject_id" %in% names(x)) n_distinct(x$subject_id) else NA,
      n_stay = if ("stay_id" %in% names(x)) n_distinct(x$stay_id) else NA,
      prevalence = mean(as.integer(as.character(x$y_prolong) == "1"), na.rm = TRUE)
    )
  })

  output$cohort_table <- renderDT({
    datatable(cohort_filtered() |> head(200),
      options = list(pageLength = 10, scrollX = TRUE)
    )
  })

  # ---- Tab 2: Patient trajectory ----
  patient_rows <- reactive({
    req("subject_id" %in% names(df))
    df |> filter(subject_id == input$subj)
  })

  output$stay_picker_ui <- renderUI({
    x <- patient_rows()
    if (!("stay_id" %in% names(x))) return(NULL)
    stays <- sort(unique(x$stay_id))
    selectInput("stay_pick", "stay_id", choices = stays, selected = stays[1])
  })

  output$patient_stays <- renderDT({
    x <- patient_rows()
    cols <- intersect(c("subject_id","hadm_id","stay_id","y_prolong","vent_hr","vent_start","vent_end"), names(x))
    datatable(x |> select(all_of(cols)), options = list(pageLength = 10, scrollX = TRUE))
  })

  output$vent_plot <- renderPlot({
    x <- patient_rows()
    if (!all(c("stay_id","vent_hr","y_prolong") %in% names(x))) return(NULL)
    ggplot(x, aes(x = factor(stay_id), y = vent_hr, fill = y_prolong)) +
      geom_col() +
      coord_flip() +
      labs(x = "stay_id", y = "vent_hr", title = "Vent hours by stay") +
      theme_minimal()
  })

  output$stay_snapshot <- renderDT({
    x <- patient_rows()
    req("stay_id" %in% names(x), input$stay_pick)
    one <- x |> filter(stay_id == input$stay_pick) |> slice(1)
    show_cols <- intersect(input$snap_cols, names(one))
    datatable(one |> select(any_of(c("subject_id","hadm_id","stay_id","y_prolong")), all_of(show_cols)),
              options = list(dom = "t", scrollX = TRUE))
  })

  # ---- Tab 3: ML prediction ----
  chosen_wf <- reactive({
    models[[input$model_choice]]
  })

  pred_input <- eventReactive(input$run_pred, {
    if (input$pred_mode == "Use a stay from dataset") {
      req("stay_id" %in% names(df))
      one <- df |> filter(stay_id == input$pred_stay) |> slice(1)
      one |> select(-any_of("y_prolong"))
    } else {
      one <- tibble()

      # numeric
      if ("anchor_age" %in% names(df)) one$anchor_age <- safe_num(input$in_age)
      if ("bmi" %in% names(df)) one$bmi <- safe_num(input$in_bmi)
      if ("sbp" %in% names(df)) one$sbp <- safe_num(input$in_sbp)
      if ("dbp" %in% names(df)) one$dbp <- safe_num(input$in_dbp)
      if ("UreaNitrogen" %in% names(df)) one$UreaNitrogen <- safe_num(input$in_bun)
      if ("creatinine" %in% names(df)) one$creatinine <- safe_num(input$in_cr)
      if ("potassium" %in% names(df)) one$potassium <- safe_num(input$in_k)
      if ("sodium" %in% names(df)) one$sodium <- safe_num(input$in_na)
      if ("heart_rate" %in% names(df)) one$heart_rate <- safe_num(input$in_hr)
      if ("systolic_bp" %in% names(df)) one$systolic_bp <- safe_num(input$in_sbp2)
      if ("diastolic_bp" %in% names(df)) one$diastolic_bp <- safe_num(input$in_dbp2)
      if ("temperature_c" %in% names(df)) one$temperature_c <- safe_num(input$in_temp)
      if ("respiratory_rate" %in% names(df)) one$respiratory_rate <- safe_num(input$in_rr)

      # categorical
      if ("gender" %in% names(df)) one$gender <- as.character(input$in_gender)

      one
    }
  })

  output$pred_input_view <- renderDT({
    req(pred_input())
    datatable(pred_input(), options = list(dom = "t", scrollX = TRUE))
  })

  # probability for selected model
  pred_prob <- eventReactive(input$run_pred, {
    new_data <- pred_input()
    wf <- chosen_wf()
    p <- predict(wf, new_data = new_data, type = "prob")
    as.numeric(p$.pred_1)
  })

  # probabilities for all models (nice demo)
  pred_all_models <- eventReactive(input$run_pred, {
    new_data <- pred_input()
    tibble(
      model = names(models),
      prob_prolong = map_dbl(models, \(wf) as.numeric(predict(wf, new_data = new_data, type = "prob")$.pred_1))
    )
  })

  output$pred_all_models_tbl <- renderDT({
    req(pred_all_models())
    datatable(pred_all_models(), options = list(dom = "t", pageLength = 5))
  })

  output$pred_bar <- renderPlot({
    req(pred_all_models())
    x <- pred_all_models()
    ggplot(x, aes(x = model, y = prob_prolong)) +
      geom_col() +
      ylim(0, 1) +
      labs(x = NULL, y = "P(y_prolong = 1)", title = "Predicted probability by model") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 15, hjust = 1))
  })

  output$pred_out <- renderPrint({
    req(pred_prob())
    p1 <- pred_prob()
    cls <- ifelse(p1 >= input$thr, "1 (prolonged)", "0 (not prolonged)")
    list(
      selected_model = input$model_choice,
      prob_prolonged = round(p1, 4),
      threshold = input$thr,
      predicted_class = cls
    )
  })
}

shinyApp(ui, server)