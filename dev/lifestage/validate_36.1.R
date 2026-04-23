#!/usr/bin/env Rscript
# Phase 36.1: Unresolved Coverage Audit Validation
# Run from project root: Rscript dev/lifestage/validate_36.1.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

cli::cli_h1("Phase 36.1 Validation")

# -- Section 1: Audit CSV Schema Check ----------------------------------------

cli::cli_h2("1. Audit CSV Schema Check")

audit_path <- system.file(
  "extdata",
  "ecotox",
  "lifestage_audit.csv",
  package = "ComptoxR"
)
if (!nzchar(audit_path)) {
  audit_path <- file.path("inst", "extdata", "ecotox", "lifestage_audit.csv")
}
stopifnot(file.exists(audit_path))

audit <- readr::read_csv(audit_path, show_col_types = FALSE)

expected_cols <- c(
  "org_lifestage",
  "triage_bucket",
  "resolution_path",
  "candidate_source",
  "notes"
)
stopifnot(all(expected_cols %in% names(audit)))

cli::cli_alert_success(
  "Audit schema: {ncol(audit)} columns ({.val {paste(names(audit), collapse = ', ')}})"
)

# -- Section 2: 100% Classification Coverage (D-03) ---------------------------

cli::cli_h2("2. 100% Classification Coverage (D-03)")

baseline_path <- system.file(
  "extdata",
  "ecotox",
  "lifestage_baseline.csv",
  package = "ComptoxR"
)
if (!nzchar(baseline_path)) {
  baseline_path <- file.path("inst", "extdata", "ecotox", "lifestage_baseline.csv")
}
stopifnot(file.exists(baseline_path))

baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
unresolved <- dplyr::filter(baseline, source_match_status == "unresolved")
gaps <- dplyr::anti_join(unresolved, audit, by = "org_lifestage")

if (nrow(gaps) > 0) {
  cli::cli_abort(
    "Missing audit classification for {nrow(gaps)} term(s): {.val {gaps$org_lifestage}}"
  )
}
stopifnot(nrow(gaps) == 0L)

cli::cli_alert_success(
  "All {nrow(unresolved)} unresolved term(s) classified in audit CSV."
)

bucket_counts <- sort(table(audit$triage_bucket), decreasing = TRUE)
cli::cli_inform("Bucket breakdown:")
for (bucket in names(bucket_counts)) {
  cli::cli_inform("  {bucket}: {bucket_counts[[bucket]]}")
}

# -- Section 3: Administrative Derivation Rows (D-02) -------------------------

cli::cli_h2("3. Administrative Derivation Rows (D-02)")

derivation_path <- system.file(
  "extdata",
  "ecotox",
  "lifestage_derivation.csv",
  package = "ComptoxR"
)
if (!nzchar(derivation_path)) {
  derivation_path <- file.path("inst", "extdata", "ecotox", "lifestage_derivation.csv")
}
stopifnot(file.exists(derivation_path))

derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)
admin_rows <- dplyr::filter(
  derivation,
  derivation_source == "administrative_noise_audit"
)

stopifnot(nrow(admin_rows) >= 4L)

cli::cli_alert_success(
  "{nrow(admin_rows)} administrative_noise_audit row(s) found in derivation CSV."
)
cli::cli_inform(
  "Total derivation rows: {nrow(derivation)} (53 baseline + {nrow(admin_rows)} admin)"
)

# -- Section 4: cli_warn Gate Presence Check -----------------------------------

cli::cli_h2("4. cli_warn Gate Presence")

patch_path <- file.path("R", "eco_lifestage_patch.R")
stopifnot(file.exists(patch_path))

patch_lines <- readLines(patch_path, warn = FALSE)
gate_present <- any(grepl("not found in lifestage audit CSV", patch_lines, fixed = TRUE))
stopifnot(gate_present)

no_abort_in_gate <- !any(grepl("cli_abort.*audit", patch_lines))
stopifnot(no_abort_in_gate)

cli::cli_alert_success(
  "cli_warn gate string found in {.path {patch_path}}"
)
cli::cli_alert_success(
  "No cli_abort in audit gate block (warn-only per D-11)"
)

# -- Footer -------------------------------------------------------------------

cli::cli_h1("Phase 36.1 Validation Complete")
cli::cli_alert_success("All checks passed.")
