#!/usr/bin/env Rscript
# Lifestage Baseline Refresh Script
# Run when a new ECOTOX release is installed in ecotox.duckdb.
# Run from project root: Rscript dev/lifestage/refresh_baseline.R
#
# Prerequisites:
#   - ecotox.duckdb exists with new release data
#   - OLS4 and NVS APIs are reachable (network access required)
#
# Output:
#   - Updates inst/extdata/ecotox/lifestage_baseline.csv (D-13)
#   - Writes dev/lifestage/derivation_proposals.csv for new unseen keys (D-14)
#   - NEVER writes directly to lifestage_derivation.csv (D-02)

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

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

cli::cli_h2("Step 2: Re-resolve All Terms")
cli::cli_alert_info(
  "Resolving {length(org_lifestages)} term(s) via OLS4 + NVS..."
)

re_resolved <- purrr::map_dfr(
  org_lifestages,
  .eco_lifestage_resolve_term,
  ecotox_release = ecotox_release
)

utils::write.csv(
  re_resolved,
  .eco_lifestage_baseline_path(),
  row.names = FALSE,
  na = ""
)
cli::cli_alert_success(
  "Baseline written: {nrow(re_resolved)} rows to {.path {.eco_lifestage_baseline_path()}}."
)

# -- Step 3: Check Derivation Coverage --------------------------------------

cli::cli_h2("Step 3: Check Derivation Coverage")

derivation <- .eco_lifestage_derivation_map()

resolved_new <- re_resolved |>
  dplyr::filter(source_match_status == "resolved") |>
  dplyr::distinct(source_ontology, source_term_id)

new_keys <- dplyr::anti_join(
  resolved_new,
  derivation,
  by = c("source_ontology", "source_term_id")
)

if (nrow(new_keys) > 0) {
  proposals_path <- file.path("dev", "lifestage", "derivation_proposals.csv")

  proposals <- new_keys |>
    dplyr::mutate(
      harmonized_life_stage = NA_character_,
      reproductive_stage = NA,
      derivation_source = "curator_review"
    )

  utils::write.csv(proposals, proposals_path, row.names = FALSE, na = "")

  cli::cli_warn(c(
    "{nrow(new_keys)} new resolved key(s) have no derivation partner.",
    "i" = "Review {.path {proposals_path}} and promote approved rows to {.path inst/extdata/ecotox/lifestage_derivation.csv}."
  ))
} else {
  cli::cli_alert_success("All resolved keys already have derivation partners.")
}

# -- Footer -----------------------------------------------------------------

cli::cli_alert_success("Refresh complete.")
