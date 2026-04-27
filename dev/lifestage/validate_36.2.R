#!/usr/bin/env Rscript
# Phase 36.2: Dictionary Rebuild Validation
# Run from project root: Rscript dev/lifestage/validate_36.2.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

csv_path <- function(filename) {
  path <- file.path("inst", "extdata", "ecotox", filename)
  if (!file.exists(path)) {
    path <- system.file("extdata", "ecotox", filename, package = "ComptoxR")
  }
  stopifnot(file.exists(path))
  path
}

cli::cli_h1("Phase 36.2 Validation")

# -- Section 1: Baseline Schema Check ---------------------------------------

cli::cli_h2("1. Baseline Schema Check")

baseline <- readr::read_csv(csv_path("lifestage_baseline.csv"), show_col_types = FALSE)
stopifnot(ncol(baseline) == 13L)
stopifnot(nrow(baseline) == 139L)

resolved_count <- sum(baseline$source_match_status == "resolved", na.rm = TRUE)
ambiguous_count <- sum(baseline$source_match_status == "ambiguous", na.rm = TRUE)
unresolved_count <- sum(baseline$source_match_status == "unresolved", na.rm = TRUE)
cli::cli_alert_success(
  "Baseline rows: {nrow(baseline)} with {resolved_count} resolved, {ambiguous_count} ambiguous, {unresolved_count} unresolved."
)

# -- Section 2: Alias CSV Schema Check --------------------------------------

cli::cli_h2("2. Alias CSV Schema Check")

aliases <- readr::read_csv(csv_path("lifestage_aliases.csv"), show_col_types = FALSE)
stopifnot(all(c("org_lifestage", "normalized_query") %in% names(aliases)))
stopifnot(nrow(aliases) == dplyr::n_distinct(aliases$org_lifestage))
cli::cli_alert_success(
  "Alias CSV rows: {nrow(aliases)} with no duplicate org_lifestage keys."
)

# -- Section 3: Derivation Schema Check -------------------------------------

cli::cli_h2("3. Derivation Schema Check")

derivation <- readr::read_csv(csv_path("lifestage_derivation.csv"), show_col_types = FALSE)
expected_derivation_cols <- c(
  "source_ontology",
  "source_term_id",
  "harmonized_life_stage",
  "reproductive_stage",
  "derivation_source"
)
stopifnot(ncol(derivation) == 5L)
stopifnot(identical(sort(names(derivation)), sort(expected_derivation_cols)))
stopifnot(nrow(derivation) > 57L)
cli::cli_alert_success(
  "Derivation rows: {nrow(derivation)} with expected 5-column schema."
)

# -- Section 4: Derivation Coverage Report -----------------------------------

cli::cli_h2("4. Derivation Coverage Report")

coverage_report <- .eco_lifestage_derivation_coverage_report(baseline)
stopifnot(sum(coverage_report$coverage_source == "missing_both", na.rm = TRUE) == 0L)

report_path <- .eco_lifestage_derivation_coverage_report_path()
utils::write.csv(coverage_report, report_path, row.names = FALSE, na = "")

csv_only_count <- sum(coverage_report$coverage_source == "derivation_csv_only", na.rm = TRUE)
cli::cli_alert_success(
  "Resolved ID coverage: {csv_only_count} derivation-CSV-covered, 0 missing both."
)

# -- Section 5: 100% Coverage Gate ------------------------------------------

cli::cli_h2("5. 100% Coverage Gate (D-07)")

audit <- readr::read_csv(csv_path("lifestage_audit.csv"), show_col_types = FALSE)
resolved_rows <- baseline |>
  dplyr::filter(.data$source_match_status == "resolved") |>
  dplyr::group_by(.data$org_lifestage) |>
  dplyr::slice(1) |>
  dplyr::ungroup()
resolved_with_derivation <- resolved_rows |>
  dplyr::distinct(.data$org_lifestage, .data$source_ontology, .data$source_term_id) |>
  dplyr::semi_join(derivation, by = c("source_ontology", "source_term_id")) |>
  dplyr::distinct(.data$org_lifestage)
explicit_unresolved <- derivation |>
  dplyr::filter(.data$source_ontology == "ECOTOX_UNRESOLVED") |>
  dplyr::transmute(org_lifestage = .data$source_term_id)
unresolved_terms <- baseline |>
  dplyr::filter(.data$source_match_status == "unresolved") |>
  dplyr::distinct(.data$org_lifestage)
missing_audit <- unresolved_terms |>
  dplyr::anti_join(
    audit |> dplyr::distinct(.data$org_lifestage),
    by = "org_lifestage"
  )
missing_unresolved_derivation <- unresolved_terms |>
  dplyr::anti_join(explicit_unresolved, by = "org_lifestage")
if (nrow(missing_audit) > 0) {
  cli::cli_abort(
    "{nrow(missing_audit)} unresolved term(s) have no audit row: {.val {missing_audit$org_lifestage}}"
  )
}
if (nrow(missing_unresolved_derivation) > 0) {
  cli::cli_abort(
    "{nrow(missing_unresolved_derivation)} unresolved term(s) have no ECOTOX_UNRESOLVED derivation row: {.val {missing_unresolved_derivation$org_lifestage}}"
  )
}
cli::cli_alert_success("Every unresolved baseline term has audit and ECOTOX_UNRESOLVED derivation coverage.")
covered_terms <- dplyr::bind_rows(
  resolved_with_derivation,
  explicit_unresolved
) |>
  dplyr::distinct(.data$org_lifestage)
coverage_gaps <- baseline |>
  dplyr::distinct(.data$org_lifestage) |>
  dplyr::anti_join(covered_terms, by = "org_lifestage")

if (nrow(coverage_gaps) > 0) {
  cli::cli_abort(
    "Coverage gaps found for {nrow(coverage_gaps)} term(s): {.val {coverage_gaps$org_lifestage}}"
  )
}
stopifnot(nrow(coverage_gaps) == 0L)
cli::cli_alert_success("Every baseline term is covered by a resolved or explicit unresolved derivation path.")

# -- Section 6: No Orphaned Derivation Rows ---------------------------------

cli::cli_h2("6. No Orphaned Derivation Rows")

resolved_keys <- baseline |>
  dplyr::filter(.data$source_match_status == "resolved") |>
  dplyr::distinct(.data$source_ontology, .data$source_term_id)
auto_unmatched_resolved <- derivation |>
  dplyr::filter(.data$derivation_source == "auto_unmatched_needs_review") |>
  dplyr::semi_join(resolved_keys, by = c("source_ontology", "source_term_id"))
if (nrow(auto_unmatched_resolved) > 0) {
  cli::cli_abort(
    "{nrow(auto_unmatched_resolved)} resolved derivation key(s) still need manual category review: {.val {paste0(auto_unmatched_resolved$source_ontology, ':', auto_unmatched_resolved$source_term_id)}}"
  )
}
cli::cli_alert_success("No resolved baseline keys remain marked auto_unmatched_needs_review.")
orphans <- derivation |>
  dplyr::filter(!is.na(.data$source_ontology), !is.na(.data$source_term_id)) |>
  dplyr::filter(.data$source_ontology != "ECOTOX_UNRESOLVED") |>
  dplyr::anti_join(resolved_keys, by = c("source_ontology", "source_term_id")) |>
  dplyr::filter(.data$derivation_source != "baseline_curated_source_id")

if (nrow(orphans) > 0) {
  cli::cli_warn(
    "{nrow(orphans)} derivation row(s) do not map back to resolved baseline keys: {.val {paste0(orphans$source_ontology, ':', orphans$source_term_id)}}"
  )
} else {
  cli::cli_alert_success("No non-curated orphaned derivation rows found.")
}

# -- Section 7: Cross-Check Gate --------------------------------------------

cli::cli_h2("7. Cross-Check Gate")

gaps <- dplyr::anti_join(
  resolved_keys,
  derivation,
  by = c("source_ontology", "source_term_id")
)
if (nrow(gaps) > 0) {
  cli::cli_abort(
    "{nrow(gaps)} resolved key(s) have no derivation partner: {.val {paste0(gaps$source_ontology, ':', gaps$source_term_id)}}"
  )
}
stopifnot(nrow(gaps) == 0L)
cli::cli_alert_success("Every resolved baseline key has a derivation partner.")

# -- Section 8: GO:0040007 Contamination Check ------------------------------

cli::cli_h2("8. GO:0040007 Contamination Check")

stopifnot(sum(baseline$source_term_id == "GO:0040007", na.rm = TRUE) == 0L)
cli::cli_alert_success("No GO:0040007 contamination in the regenerated baseline.")

cli::cli_h1("Phase 36.2 Validation Complete")
cli::cli_alert_success("All checks passed.")
