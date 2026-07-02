#!/usr/bin/env Rscript
# Phase 36: Bootstrap Data Artifacts Validation
# Run from project root: Rscript dev/lifestage/validate_36.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

cli::cli_h1("Phase 36 Validation")

# -- Section 1: Schema Checks -----------------------------------------------

cli::cli_h2("1. Schema Checks")

baseline_path <- .eco_lifestage_baseline_path()
derivation_path <- .eco_lifestage_derivation_path()

baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)

stopifnot(ncol(baseline) == 13L)
cli::cli_alert_success(
  "Baseline schema: {ncol(baseline)} columns ({.val {paste(names(baseline), collapse = ', ')}})"
)

stopifnot(ncol(derivation) == 5L)
cli::cli_alert_success(
  "Derivation schema: {ncol(derivation)} columns ({.val {paste(names(derivation), collapse = ', ')}})"
)

# -- Section 2: Cross-Check Gate --------------------------------------------

cli::cli_h2("2. Cross-Check Gate")

resolved <- dplyr::filter(baseline, source_match_status == "resolved")
resolved_keys <- dplyr::distinct(resolved, source_ontology, source_term_id)
gaps <- dplyr::anti_join(
  resolved_keys,
  derivation,
  by = c("source_ontology", "source_term_id")
)

stopifnot(nrow(gaps) == 0L)
cli::cli_alert_success(
  "Cross-check: {nrow(resolved_keys)} resolved key(s) all have derivation partners."
)

# -- Section 3: GO:0040007 Contamination Check ------------------------------

cli::cli_h2("3. GO:0040007 Contamination Check")

go_rows <- baseline[!is.na(baseline$source_term_id) & baseline$source_term_id == "GO:0040007", ]

stopifnot(nrow(go_rows) == 0L)
cli::cli_alert_success("No GO:0040007 contamination in baseline.")

# -- Section 4: Completeness Check (DB-optional) ----------------------------

cli::cli_h2("4. Completeness Check")

db_path <- eco_path()

if (!file.exists(db_path)) {
  cli::cli_warn(
    "ECOTOX DB not found at {.path {db_path}} -- completeness check skipped."
  )
} else {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  # Release match (D-07)
  db_release <- .eco_lifestage_release_id(con)
  baseline_release <- unique(stats::na.omit(baseline$ecotox_release))

  if (!identical(db_release, baseline_release)) {
    cli::cli_abort(
      "Release mismatch: DB={.val {db_release}}, baseline={.val {baseline_release}}"
    )
  }
  cli::cli_alert_success(
    "Release match: DB and baseline both on {.val {db_release}}."
  )

  # Completeness anti-join (D-06)
  db_terms <- DBI::dbGetQuery(
    con,
    "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
  )$description

  missing_from_baseline <- setdiff(db_terms, baseline$org_lifestage)

  if (length(missing_from_baseline) == 0) {
    cli::cli_alert_success(
      "Completeness: all {length(db_terms)} DB term(s) present in baseline."
    )
  } else {
    cli::cli_abort(
      "Baseline missing {length(missing_from_baseline)} DB term(s): {missing_from_baseline}"
    )
  }
}

# -- Footer -----------------------------------------------------------------

cli::cli_h1("Phase 36 Validation Complete")
cli::cli_alert_success("All checks passed.")
