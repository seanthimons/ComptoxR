#!/usr/bin/env Rscript
# Incremental lifestage refresh for a subset of terms.
# Default: rerun all non-resolved baseline terms.
# Usage:
#   Rscript dev/lifestage/refresh_subset.R
#   Rscript dev/lifestage/refresh_subset.R "Copepodid" "Prepupal"

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

csv_path <- function(filename) {
  path <- file.path("dev", "lifestage", "source", filename)
  path
}

cli::cli_h1("Incremental Lifestage Refresh")

db_path <- eco_path()
if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {db_path}}.")
}

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

ecotox_release <- .eco_lifestage_release_id(con)
baseline_path <- csv_path("lifestage_baseline.csv")
audit_path <- csv_path("lifestage_audit.csv")

current_baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
current_cache <- .eco_lifestage_cache_read(ecotox_release, required = FALSE)
if (nrow(current_cache) == 0) {
  current_cache <- current_baseline
}

args <- commandArgs(trailingOnly = TRUE)
target_terms <- if (length(args) > 0) {
  unique(args)
} else {
  current_baseline |>
    dplyr::filter(.data$source_match_status != "resolved") |>
    dplyr::pull(.data$org_lifestage) |>
    unique()
}

if (length(target_terms) == 0) {
  cli::cli_alert_success("No non-resolved terms to rerun.")
  quit(save = "no", status = 0)
}

cli::cli_alert_info(
  "Rerunning {length(target_terms)} term(s) against the current provider pipeline."
)

progress_bar <- cli::cli_progress_bar(
  "Refreshing subset",
  total = length(target_terms),
  format = "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} | {cli::pb_percent} | eta: {cli::pb_eta}"
)

rerun_parts <- vector("list", length(target_terms))
for (i in seq_along(target_terms)) {
  term <- target_terms[[i]]
  rerun_parts[[i]] <- .eco_lifestage_resolve_term(term, ecotox_release = ecotox_release)
  cli::cli_progress_update(id = progress_bar, set = i)
  if (i %% 10L == 0L || i == length(target_terms)) {
    cli::cli_alert_info(
      "Subset checkpoint: {i}/{length(target_terms)} terms processed (latest: {.val {term}})."
    )
  }
}
cli::cli_progress_done(id = progress_bar)

rerun_cache <- dplyr::bind_rows(rerun_parts)
merged_cache <- current_cache |>
  dplyr::filter(!.data$org_lifestage %in% target_terms) |>
  dplyr::bind_rows(rerun_cache) |>
  dplyr::arrange(.data$org_lifestage, .data$candidate_rank)

.eco_lifestage_cache_write(merged_cache, ecotox_release)

updated_baseline <- collapse_baseline_rows(merged_cache)
utils::write.csv(updated_baseline, baseline_path, row.names = FALSE, na = "")

review_info <- write_resolution_review(merged_cache)
audit <- if (file.exists(audit_path)) {
  readr::read_csv(audit_path, show_col_types = FALSE)
} else {
  NULL
}
updated_derivation <- .eco_lifestage_auto_derive(updated_baseline, audit)
derivation_path <- .eco_lifestage_derivation_path()
utils::write.csv(updated_derivation, derivation_path, row.names = FALSE, na = "")
coverage_info <- .eco_lifestage_write_derivation_coverage_report(updated_baseline)

resolved_count <- sum(updated_baseline$source_match_status == "resolved", na.rm = TRUE)
ambiguous_count <- sum(updated_baseline$source_match_status == "ambiguous", na.rm = TRUE)
unresolved_count <- sum(updated_baseline$source_match_status == "unresolved", na.rm = TRUE)

cli::cli_alert_success(
  "Baseline updated: {nrow(updated_baseline)} terms, {resolved_count} resolved, {ambiguous_count} ambiguous, {unresolved_count} unresolved."
)
cli::cli_alert_info(
  "Resolution review written: {review_info$rows} rows to {.path {review_info$path}}."
)
cli::cli_alert_info(
  "Derivation rows: {nrow(updated_derivation)} written to {.path {derivation_path}}."
)
cli::cli_alert_info(
  "Derivation coverage report: {coverage_info$rows} resolved IDs, {coverage_info$derivation_csv_only} covered by derivation CSV, {coverage_info$missing_both} missing both, written to {.path {coverage_info$path}}."
)
cli::cli_alert_info(
  "Next: rerun {.code Rscript dev/lifestage/validate_36.2.R} after targeted fixes."
)
