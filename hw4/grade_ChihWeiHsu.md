*Chih Wei Hsu*

### Overall Grade: 263/270

### Late penalty

- Is the homework submitted (git tag time) before deadline? Take 10 pts off per day for late submission.  

### Quality of report: 10/10

-   Is the final report in a human readable format html? 

-   Is the report prepared as a dynamic document (Quarto) for better reproducibility?

-   Is the report clear (whole sentences, typos, grammar)? Do readers have a clear idea what's going on and how results are produced by just reading the report? Take some points off if the solutions are too succinct to grasp, or there are too many typos/grammar. 

### Completeness, correctness and efficiency of solution: 215/220

- Q1 (95/100)

If `collect` before end of Q1.7, take 20 points off.

If ever put the BigQuery token in Git, take 50 points off.

Cohort in Q1.7 should match that in HW3.

Q1.8 summaries should roughly match those given.

  - Q1.5 & Q1.6 (-5 total): Missing `arrange(subject_id, stay_id)` at the end of both the labevents and chartevents pipe chains. Output order will not match the ground truth. Single 5-point deduction applied.
  - Q1.7: `collect()` is correctly placed near the end (line 281). `arrange(subject_id, hadm_id, stay_id)` is present after `collect()`. No early collect penalty.
  - Q1.8: `fct_lump_n` correctly applied to all five variables. `fct_collapse` used for race to ASIAN/BLACK/HISPANIC/WHITE/Other. `los_long = los >= 2` correct.

- Q2 (100/100)

  - **Folder structure**: Separate `app_block.R` file provided in `mimiciv_shiny/`. No penalty.
  - **Tab 1 (Cohort Explorer)**: Includes all three variable categories (Demographics, Labs, Vitals) with a grouped dropdown via `switch()` — *bonus: +5 for grouped variable categories with dropdown*. Histogram/boxplot plots and summary table displayed.
  - **Tab 2 (Patient Explorer)**: Contains both an ADT timeline plot and an ICU vitals faceted plot, both fetching data from BigQuery via `tbl(con_bq, ...)`. Patient ID is entered via `numericInput` — *bonus: +5 for numeric input instead of dropdown*.
  - (-3): After `collect()` from BigQuery, datetime column (`charttime`) are not converted to POSIXct.
  - (-5): Diagnoses retrieved via `slice_head(n = 3)` without `arrange(seq_num)`. Not sorted by clinical priority.
  - (-2): `lab_vars` includes "Hemoglobin" and "Platelet_Count" which likely do not exist in the cohort RDS, causing empty output if selected.
  - **Error handling**: Uses `req()` and `eventReactive`. No `tryCatch` or `validate` wrappers. No `onStop()` for BigQuery connection teardown.

- Q3 (20/20)

  - Lists AI tools (GitHub Copilot, ChatGPT) and discusses their use.
  - Provides 5 instances of AI errors/inaccuracies (left_join NAs, ID type conversion, pivot_wider in BigQuery, Shiny timeline, tbl_summary dod issue). Full credit.

### Usage of Git: 10/10

-   Are branches (`main` and `develop`) correctly set up? Is the hw submission put into the `main` branch?

-   Are there enough commits (>=5) in develop branch? Are commit messages clear? The commits should span out not clustered the day before deadline. 
          
-   Is the hw submission tagged? 

-   Are the folders (`hw1`, `hw2`, ...) created correctly? 
  
-   Do not put a lot auxiliary files into version control. 

-   If those gz data files are in Git, take 5 points off.

### Reproducibility: 10/10

-   Are the materials (files and instructions) submitted to the `main` branch sufficient for reproducing all the results? Just click the `Render` button will produce the final `html`? 

-   If necessary, are there clear instructions, either in report or in a separate file, how to reproduce the results?

### R code style: 18/20

For bash commands, only enforce the 80-character rule. Take 2 pts off for each violation. 

-   [Rule 2.6](https://style.tidyverse.org/syntax.html#long-function-calls) The maximum line length is 80 characters. Long URLs and strings are exceptions.  
    - No violations found.

-   [Rule 2.5.1](https://style.tidyverse.org/syntax.html#indenting) When indenting your code, use two spaces.  
    - No violations found.

-   [Rule 2.2.4](https://style.tidyverse.org/syntax.html#infix-operators) Place spaces around all infix operators (=, +, -, <-, etc.).  
    - (-2) Line 101: `patients_tble <-tbl(con_bq, ...)` — missing space before `tbl` after `<-`.

-   [Rule 2.2.1.](https://style.tidyverse.org/syntax.html#commas) Do not place a space before a comma, but always place one after a comma.  
    - No violations found.

-   [Rule 2.2.2](https://style.tidyverse.org/syntax.html#parentheses) Do not place spaces around code in parentheses or square brackets. Place a space before left parenthesis, except in a function call.
    - No violations found.
