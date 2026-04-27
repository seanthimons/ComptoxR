#!/usr/bin/env Rscript
# Lifestage Baseline Refresh Script
# Run when a new ECOTOX release is installed in ecotox.duckdb.
# Run from project root: Rscript dev/lifestage/refresh_baseline.R
#
# Prerequisites:
#   - ecotox.duckdb exists with new release data
#   - Network access for OLS4, NVS, Wikidata, AGROVOC, and optionally BioPortal

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

collapse_baseline_rows <- function(cache_rows) {
  cache_rows |>
    dplyr::arrange(.data$org_lifestage, .data$candidate_rank) |>
    dplyr::group_by(.data$org_lifestage) |>
    dplyr::slice(1) |>
    dplyr::ungroup()
}

write_resolution_review <- function(cache_rows) {
  review_path <- file.path("dev", "lifestage", "lifestage_resolution_review.csv")
  review_rows <- cache_rows |>
    dplyr::filter(.data$source_match_status %in% c("ambiguous", "unresolved")) |>
    dplyr::arrange(.data$org_lifestage, .data$candidate_rank)
  utils::write.csv(review_rows, review_path, row.names = FALSE, na = "")
  list(path = review_path, rows = nrow(review_rows))
}

# -- Step 1: Fetch DB Terms -------------------------------------------------

cli::cli_h1("Lifestage Baseline Refresh")
cli::cli_h2("Step 1: Fetch DB Terms")

db_path <- eco_path()

if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {db_path}}.")
}

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

ecotox_release <- .eco_lifestage_release_id(con)
org_lifestages <- DBI::dbGetQuery(
  con,
  "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
)$description

cli::cli_alert_info(
  "Found {length(org_lifestages)} distinct lifestage term(s) for release {.val {ecotox_release}}."
)

# -- Step 2: Re-resolve All Terms -------------------------------------------

cli::cli_h2("Step 2: Re-resolve All Terms (Alias + OLS4 + BioPortal + NVS + Wikidata + AGROVOC)")
cli::cli_alert_info(
  "Resolving {length(org_lifestages)} term(s) via expanded 6-source pipeline..."
)
cli::cli_alert_info(
  "Expected runtime: ~15-20 minutes (rate-limited API calls across 6 sources)."
)
cli::cli_alert_info(
  "BioPortal requires BIOPORTAL_API_KEY env var (optional -- graceful degradation if missing)."
)

progress_bar <- cli::cli_progress_bar(
  "Resolving lifestage terms",
  total = length(org_lifestages),
  format = "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} | {cli::pb_percent} | eta: {cli::pb_eta}"
)

re_resolved_parts <- vector("list", length(org_lifestages))
for (i in seq_along(org_lifestages)) {
  term <- org_lifestages[[i]]
  re_resolved_parts[[i]] <- .eco_lifestage_resolve_term(
    term,
    ecotox_release = ecotox_release
  )
  cli::cli_progress_update(id = progress_bar, set = i)

  if (i %% 10L == 0L || i == length(org_lifestages)) {
    cli::cli_alert_info(
      "Progress checkpoint: {i}/{length(org_lifestages)} terms processed (latest: {.val {term}})."
    )
  }
}
cli::cli_progress_done(id = progress_bar)

re_resolved <- dplyr::bind_rows(re_resolved_parts)
.eco_lifestage_cache_write(re_resolved, ecotox_release)

baseline_rows <- collapse_baseline_rows(re_resolved)
review_info <- write_resolution_review(re_resolved)

baseline_path <- .eco_lifestage_baseline_path()
utils::write.csv(
  baseline_rows,
  baseline_path,
  row.names = FALSE,
  na = ""
)
cli::cli_alert_success(
  "Baseline written: {nrow(baseline_rows)} rows to {.path {baseline_path}}."
)
cli::cli_alert_info(
  "Resolution review written: {review_info$rows} rows to {.path {review_info$path}}."
)

resolved_count <- sum(baseline_rows$source_match_status == "resolved", na.rm = TRUE)
unresolved_count <- sum(baseline_rows$source_match_status == "unresolved", na.rm = TRUE)
ambiguous_count <- sum(baseline_rows$source_match_status == "ambiguous", na.rm = TRUE)
cli::cli_alert_info(
  "Coverage: {resolved_count} resolved, {ambiguous_count} ambiguous, {unresolved_count} unresolved out of {nrow(baseline_rows)} terms."
)

# -- Step 3: Auto-Derive Derivation Rows ------------------------------------

cli::cli_h2("Step 3: Auto-Derive Derivation Rows")

audit_path <- system.file(
  "extdata",
  "ecotox",
  "lifestage_audit.csv",
  package = "ComptoxR"
)
if (!nzchar(audit_path)) {
  audit_path <- file.path("inst", "extdata", "ecotox", "lifestage_audit.csv")
}
audit <- if (file.exists(audit_path)) {
  readr::read_csv(audit_path, show_col_types = FALSE)
} else {
  NULL
}

new_derivation <- .eco_lifestage_auto_derive(baseline_rows, audit)

derivation_path <- file.path("inst", "extdata", "ecotox", "lifestage_derivation.csv")
utils::write.csv(
  new_derivation,
  derivation_path,
  row.names = FALSE,
  na = ""
)
cli::cli_alert_success(
  "Derivation written: {nrow(new_derivation)} rows to {.path {derivation_path}}."
)
coverage_info <- .eco_lifestage_write_derivation_coverage_report(baseline_rows)
cli::cli_alert_info(
  "Derivation coverage report: {coverage_info$rows} resolved IDs, {coverage_info$derivation_csv_only} covered by derivation CSV, {coverage_info$missing_both} missing both, written to {.path {coverage_info$path}}."
)

needs_review <- new_derivation |>
  dplyr::filter(.data$derivation_source == "auto_unmatched_needs_review")

if (nrow(needs_review) > 0) {
  cli::cli_warn(c(
    "{nrow(needs_review)} auto-derived row(s) could not be mapped to a harmonized category.",
    "i" = "These rows have harmonized_life_stage = 'Other/Unknown' and need curator review.",
    "i" = "Review {.path {derivation_path}} and update manually if needed."
  ))
} else {
  cli::cli_alert_success("All auto-derived rows mapped to harmonized categories.")
}

# -- Step 4: Coverage Gate --------------------------------------------------

cli::cli_h2("Step 4: Coverage Gate (D-07)")

baseline_terms <- unique(baseline_rows$org_lifestage)
resolved_terms <- baseline_rows |>
  dplyr::filter(.data$source_match_status == "resolved") |>
  dplyr::pull(.data$org_lifestage) |>
  unique()

resolved_keys <- baseline_rows |>
  dplyr::filter(.data$source_match_status == "resolved") |>
  dplyr::distinct(.data$source_ontology, .data$source_term_id)

derivation_gaps <- dplyr::anti_join(
  resolved_keys,
  new_derivation,
  by = c("source_ontology", "source_term_id")
)

if (nrow(derivation_gaps) > 0) {
  cli::cli_warn(c(
    "{nrow(derivation_gaps)} resolved key(s) have no derivation partner.",
    "i" = "Keys: {.val {paste0(derivation_gaps$source_ontology, ':', derivation_gaps$source_term_id)}}"
  ))
}

unresolved_terms <- setdiff(baseline_terms, resolved_terms)
if (!is.null(audit) && length(unresolved_terms) > 0) {
  missing_audit <- setdiff(unresolved_terms, audit$org_lifestage)
  if (length(missing_audit) > 0) {
    cli::cli_warn(c(
      "{length(missing_audit)} unresolved term(s) have no audit classification.",
      "i" = "Terms: {.val {missing_audit}}"
    ))
  }
}

coverage_pct <- round(length(resolved_terms) / length(baseline_terms) * 100, 1)
cli::cli_alert_info(
  "Final coverage: {coverage_pct}% ({length(resolved_terms)}/{length(baseline_terms)} terms resolved)."
)

# -- Footer -----------------------------------------------------------------

cli::cli_h1("Refresh Complete")
cli::cli_alert_info("Next steps:")
cli::cli_alert_info("  1. Review derivation CSV: {.path {derivation_path}}")
cli::cli_alert_info("  2. Run validation: {.code Rscript dev/lifestage/validate_36.2.R}")
cli::cli_alert_info("  3. Commit both CSVs when satisfied.")
