# STAT 5014 — Homework 3

This project checks and corrects the clinic vital-sign analysis. The raw data are in `data/`, reusable functions are in `code/`, the analysis script is in `scripts/`, and the write-up is in `manuscript/`.

## Run the analysis

From the repository directory, run:

```sh
Rscript scripts/01_analyze.R
```

The script uses a fixed seed and relative paths. It leaves the raw data unchanged and recreates results in the Git-ignored `output/` directory.

## Project files

```text
README.md
LICENSE
.gitignore
data/extracted_records.csv
code/analysis.R
scripts/01_analyze.R
output/ (generated; ignored by Git)
manuscript/homework3.Rmd
```
