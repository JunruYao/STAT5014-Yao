# Reusable functions for the HW3 patient-record analysis.

clean_records <- function(records) {
  required <- c("record_id", "site", "pulse", "systolic", "diastolic", "afib", "inr", "age")
  stopifnot(all(required %in% names(records)))
  stopifnot(!anyDuplicated(records$record_id))

  original_n <- nrow(records)
  cleaned <- records
  original_site <- records$site
  cleaned$site <- tolower(trimws(gsub("[[:space:]]+", " ", cleaned$site)))
  cleaned$site <- ifelse(cleaned$site == "clinic a", "Clinic A",
                         ifelse(cleaned$site == "clinic b", "Clinic B", NA_character_))
  site_changed <- is.na(original_site) | original_site != cleaned$site
  stopifnot(!anyNA(cleaned$site)) # Catches inconsistent/unrecognized clinic labels.

  vital_signs <- c("pulse", "systolic", "diastolic")
  sentinel_cells <- 0L
  for (variable in vital_signs) {
    sentinel_cells <- sentinel_cells + sum(cleaned[[variable]] == -99, na.rm = TRUE)
    cleaned[[variable]][cleaned[[variable]] == -99] <- NA_real_
  }
  sentinel_records <- Reduce(`|`, lapply(vital_signs, function(variable) {
    !is.na(records[[variable]]) & records[[variable]] == -99
  }))
  changed_records <- sum(sentinel_records | site_changed)

  list(data = cleaned, records_read = original_n,
       records_kept = nrow(cleaned), changed_records = changed_records,
       sentinel_cells = sentinel_cells)
}

summarize_vitals <- function(records) {
  variables <- c("pulse", "systolic", "diastolic")
  labels <- c(pulse = "Pulse (beats/min)",
              systolic = "Systolic blood pressure (mmHg)",
              diastolic = "Diastolic blood pressure (mmHg)")
  do.call(rbind, lapply(variables, function(variable) {
    x <- records[[variable]]
    data.frame(variable = unname(labels[variable]),
               n = sum(!is.na(x)), mean = mean(x, na.rm = TRUE),
               sd = sd(x, na.rm = TRUE),
               stringsAsFactors = FALSE)
  }))
}

clinic_pulse_difference <- function(records) {
  clinic_a <- records$pulse[records$site == "Clinic A"]
  clinic_b <- records$pulse[records$site == "Clinic B"]
  stopifnot(length(clinic_a) > 0L, length(clinic_b) > 0L)
  c(n_a = sum(!is.na(clinic_a)), n_b = sum(!is.na(clinic_b)),
    mean_a = mean(clinic_a, na.rm = TRUE),
    mean_b = mean(clinic_b, na.rm = TRUE),
    difference_b_minus_a = mean(clinic_b, na.rm = TRUE) - mean(clinic_a, na.rm = TRUE))
}

bootstrap_pulse_difference <- function(records, replicates = 2000L) {
  clinic_a <- records$pulse[records$site == "Clinic A"]
  clinic_b <- records$pulse[records$site == "Clinic B"]
  clinic_a <- clinic_a[!is.na(clinic_a)]
  clinic_b <- clinic_b[!is.na(clinic_b)]
  differences <- replicate(replicates,
    mean(sample(clinic_b, length(clinic_b), replace = TRUE)) -
      mean(sample(clinic_a, length(clinic_a), replace = TRUE)))
  unname(quantile(differences, c(0.025, 0.975)))
}
