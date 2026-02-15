*Chih Wei Hsu*

### Overall Grade: 197/200

### Quality of report: 10/10

-   Is the homework submitted (git tag time) before deadline?  
-   Is the final report in a human readable format (html, pdf)?  
-   Is the report prepared as a dynamic document (Quarto) for better reproducibility?  
-   Is the report clear (whole sentences, typos, grammar)? Do readers have a clear idea what's going on and how results are produced by just reading the report?

### Completeness, correctness and efficiency of solution: 145/150

- Q1 (20/20)
    - Q1.1 (10/10): All three methods benchmarked with `system.time` and `pryr::object_size`. Uses `str()` to compare parsed data types across all three. Identifies `fread` as fastest. Memory comparison discussed.
    - Q1.2 (10/10): Inspects column names with `zcat | head -2 | tr ',' '\n' | nl` (nice technique). Uses `col_factor()` for categoricals, `col_integer()` for IDs, `col_datetime()` for timestamps. Reports `object_size()` under 50 MB.

- Q2 (77/80)
    - Q2.1 (10/10): Reports > 3 min, out of memory. Good explanation.
    - Q2.2 (10/10): Uses `col_select` with 4 columns. Reports it solves memory issue but still slow.
    - Q2.3 (15/15): Bash awk with shell variable passing (`-v items="$ITEMS"`), `split()` to populate `keep[]` array. Filters on `$5` (itemid). Prints `$2,$5,$7,$10`. All 9 lab item IDs. First 10 lines displayed. Row count via `wc -l`. `read_csv` timing shown.
    - Q2.4 (15/15): Correct decompression via `gzip -d -c`. Opens `labevents.csv` with `open_dataset()`. Correct select/filter/collect. `arrange()` and `head(10)` displayed separately. 33,712,352 rows (`nrow`). Arrow explanation provided.
    - Q2.5 (15/15): Writes Parquet via `write_dataset()`. Reports ~2.6 GB via `du -sh`. Correct select/filter/collect pipeline. `arrange()` and `head(10)` displayed. 33,712,352 rows. Parquet explanation provided.
    - Q2.6 (12/15): Pipes the already-collected `labevents_parquet` tibble (from Q2.5) through `select |> filter |> arrow::to_duckdb() |> collect()`. Since `labevents_parquet` was already `collect()`ed into an R tibble in Q2.5, this does not demonstrate DuckDB ingesting from Parquet files. The correct approach would be `open_dataset("./labevents_parquet", format = "parquet") |> to_duckdb() |> select() |> filter() |> collect()`. (-3)

- Q3 (30/30): Decompresses chartevents.csv.gz, writes to Parquet via `write_dataset()`. Opens Parquet with `open_dataset()`, selects subject_id/itemid/charttime/valuenum, filters for 5 vital IDs. Additionally joins with `d_items.csv.gz` to add label column (nice touch). Row count and first 10 rows with `arrange()` displayed. Well-structured multi-step approach.

- Q4 (20/20): Reports using ChatGPT/GPT-5.2 and GitHub Copilot. Five instances of AI errors described (incorrect memory/speed answers, misleading memory advice, wrong suggestion for zless, generating code for wrong question, awk exceeding line limits).

### Usage of Git: 10/10

-   Are branches (`main` and `develop`) correctly set up? Is the hw submission put into the `main` branch?  
-   Are there enough commits (>=5) in develop branch? Are commit messages clear?  
-   Is the hw2 submission tagged?  
-   Are the folders (`hw1`, `hw2`, ...) created correctly?  
-   Do not put auxiliary and big data files into version control.

### Reproducibility: 10/10

-   Are the materials (files and instructions) submitted to the `main` branch sufficient for reproducing all the results?  
-   If necessary, are there clear instructions how to reproduce the results?

### R code style: 20/20

-   [Rule 2.6](https://style.tidyverse.org/syntax.html#long-function-calls) The maximum line length is 80 characters. No violations found.
-   [Rule 2.5.1](https://style.tidyverse.org/syntax.html#indenting) When indenting your code, use two spaces. No violations found.
-   [Rule 2.2.4](https://style.tidyverse.org/syntax.html#infix-operators) Place spaces around all infix operators. No violations found.
-   [Rule 2.2.1](https://style.tidyverse.org/syntax.html#commas) Do not place a space before a comma, but always place one after a comma. No violations found.
-   [Rule 2.2.2](https://style.tidyverse.org/syntax.html#parentheses) Do not place spaces around code in parentheses or square brackets. No violations found.

Strong submission with clean code style. Creative use of shell variable passing in awk and d_items join in Q3.
