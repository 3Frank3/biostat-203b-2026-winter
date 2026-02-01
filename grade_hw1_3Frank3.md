*HSU, CHIH WEI (3Frank3)*

### Overall Grade: 108/140

---

### Quality of report: 10/10

- Is the homework submitted (git tag time) before deadline? **Yes**

- Is the final report in a human readable format html? **Yes**

- Is the report clear (whole sentences, typos, grammar)? **Yes**

---

### Completeness, correctness and efficiency of solution: 75/90

**Q1 (10/10)**

- Repository name correctly set up.

**Q2 (5/20)**

- CITI training completion link is **not provided**. The Q2 section appears incomplete, with no CITI or PhysioNet verification links displayed.

- **-15 points**: CITI training completion link not provided.

**Q3 (16/20)**

- Q3.1: OK - Created symbolic link to access data. Did not decompress gz files.

- Q3.2: OK - Displayed contents of both hosp and icu folders. Explanation for compressed files provided.

- Q3.3: **-1 point** - Incorrect explanation of `zgrep`. Student wrote "Displays the contents of a gzip-compressed file page by page using more" which is the description of `zmore`, not `zgrep`. `zgrep` is used to search patterns in compressed files.

- Q3.4: OK - Used loop to display line counts.

- Q3.5: OK - Skipped header when counting (`tail -n +2` used).

- Q3.6: **-2 points** - Used `head -n 20` which does not show all unique values.

- Q3.7: OK - Used correct columns ($3 for stay_id, $1 for subject_id).

- Q3.8: **-1 point** - File size comparison, runtime comparison, and trade-off discussion all present. However, `eval=false` without explanation.

**Q4 (15/10)**

- Q4.1: OK - Correct explanation of `wget -nc`. Loop uses `grep -o -i` which counts words. **Bonus +5 points** for counting words instead of just lines.

- Q4.2: OK - Correctly explained difference between `>` and `>>`.

- Q4.3: OK - Correctly explained the output of middle.sh and meaning of `$1`, `$2`, `$3`. Shebang explanation provided.

- middle.sh was submitted.

**Q5 (9/10)**

- Explanations provided for most commands.

- **-1 point**: Minor error in `echo {con,pre}{sent,fer}{s,ed}` explanation. You listed incorrect combinations.

**Q6 (10/10)**

- Screenshot included (`ScreenShot_4.1.5.png`).

- Used relative path, not local absolute path.

**Q7 (10/10)**

- AI assistant usage explained (GitHub Copilot, GPT-4).

- 5 instances of AI errors provided.

---

### Usage of Git: 10/10

- Are branches (`main` and `develop`) correctly set up? Is the hw submission put into the `main` branch?

- Are there enough commits (>=5) in develop branch? Are commit messages clear? The commits should span out, not clustered in the day before deadline.

- Is the hw1 submission tagged?

- Are the folders (`hw1`, `hw2`, ...) created correctly?

- Do not put auxiliary files into version control. If files such as `.Rhistory`, `.RData`, `.Rproj.user`, `.DS_Store`, etc., are in Git, take 5 points off.

- If those gz data files or `pg42671` are in Git, take 5 points off.

**No problem**

---

### Reproducibility: 5/10

- **-5 points**: The qmd file uses local paths such as `/Users/xuzhiwei/Project/UCLA_MDSH_203B/mimic/...` in several places (e.g., Q3.1 `ls -l` command, Q3.6 path). This will not work when rendering on other machines. Should use `~/mimic` consistently.

---

### R code style: 8/20

80-character rule violations (bash commands in chunks):

1. Line 89: `ls -l /Users/xuzhiwei/Project/UCLA_MDSH_203B/mimic/...` (83 chars)

2. Line 129: `zcat < ~/mimic/.../admissions.csv.gz | head -10` (81 chars)

3. Line 179: Same as above (81 chars)

4. Line 181: `zcat ... | tail -n +2 | wc -l` (91 chars)

5. Line 183: `zcat ... | awk ... | sort | uniq | wc -l` (128 chars)

6. Line 185: Same pattern (128 chars)

**6 violations × 2 points = -12 points**

Note: The 80-character rule applies specifically to bash commands within code chunks.
