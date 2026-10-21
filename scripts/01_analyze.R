# Run from the hw3 project directory with: Rscript scripts/01_analyze.R
set.seed(5014)
source("code/analysis.R")

input_path <- "data/extracted_records.csv"
output_dir <- "output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
raw_records <- read.csv(input_path, stringsAsFactors = FALSE)
cleaning <- clean_records(raw_records)
records <- cleaning$data

cat("Records read:", cleaning$records_read, "\n")
cat("Records kept:", cleaning$records_kept, "\n")
cat("Records changed:", cleaning$changed_records, "\n")
cat("-99 vital-sign cells converted to NA:", cleaning$sentinel_cells, "\n")

vital_summary <- summarize_vitals(records)
write.csv(vital_summary, file.path(output_dir, "vital_summary.csv"), row.names = FALSE)
print(vital_summary, row.names = FALSE)

clinic_summary <- clinic_pulse_difference(records)
ci <- bootstrap_pulse_difference(records)
clinic_results <- data.frame(
  clinic_a_n = unname(clinic_summary["n_a"]),
  clinic_b_n = unname(clinic_summary["n_b"]),
  clinic_a_mean_pulse = unname(clinic_summary["mean_a"]),
  clinic_b_mean_pulse = unname(clinic_summary["mean_b"]),
  difference_b_minus_a = unname(clinic_summary["difference_b_minus_a"]),
  bootstrap_95_ci_lower = ci[1], bootstrap_95_ci_upper = ci[2]
)
write.csv(clinic_results, file.path(output_dir, "clinic_pulse_difference.csv"), row.names = FALSE)
print(clinic_results, row.names = FALSE)

# A vector condition inside if() only examines one record; use a row-wise flag.
tachycardic <- records[!is.na(records$pulse) & records$pulse > 100, ]
cat("Tachycardic records (pulse > 100):", nrow(tachycardic), "\n")
png(file.path(output_dir, "pulse_by_age.png"), width = 900, height = 650)
plot(records$age, records$pulse, xlab = "Age (years)", ylab = "Pulse (beats/min)",
     main = "Pulse by age", pch = 19, col = "steelblue")
dev.off()
