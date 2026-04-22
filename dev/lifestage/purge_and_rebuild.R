#!/usr/bin/env Rscript
# TEAR-03: Purge v2.3 lifestage tables and rebuild via .eco_patch_lifestage(baseline)
# Run from: project root directory

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(dplyr)
  library(cli)
})

source("R/eco_connection.R")
source("R/eco_lifestage_patch.R")

db_path <- eco_path()

if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {db_path}}.")
}

cli::cli_h1("TEAR-03: Purge v2.3 Lifestage Tables and Rebuild")
cli::cli_alert_info("Target DB: {.path {db_path}}")

# Step 1: Drop v2.3 tables
.eco_close_con()
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)

for (tbl in c("lifestage_dictionary", "lifestage_review")) {
  if (DBI::dbExistsTable(con, tbl)) {
    DBI::dbRemoveTable(con, tbl)
    cli::cli_alert_success("Dropped {.code {tbl}}")
  } else {
    cli::cli_alert_info("{.code {tbl}} not present -- skipped")
  }
}

DBI::dbDisconnect(con, shutdown = TRUE)
.eco_close_con()

# Step 2: Rebuild via baseline
cli::cli_h2("Rebuilding via .eco_patch_lifestage(refresh = 'baseline')")
result <- .eco_patch_lifestage(db_path = db_path, refresh = "baseline")
cli::cli_alert_success("Dictionary rows: {result$dictionary_rows}")
cli::cli_alert_info("Review rows: {result$review_rows}")
cli::cli_alert_info("Refresh mode: {result$refresh_mode}")

# Step 3: Schema assertion
.eco_close_con()
con2 <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con2, shutdown = TRUE), add = TRUE)

actual_cols <- DBI::dbListFields(con2, "lifestage_dictionary")
expected_cols <- names(.eco_lifestage_dictionary_schema())

if ("ontology_id" %in% actual_cols) {
  cli::cli_abort("FAIL: ontology_id still present in lifestage_dictionary schema")
}
missing <- setdiff(expected_cols, actual_cols)
if (length(missing) > 0) {
  cli::cli_abort("FAIL: missing v2.4 columns: {paste(missing, collapse = ', ')}")
}
extra <- setdiff(actual_cols, expected_cols)
if (length(extra) > 0) {
  cli::cli_abort("FAIL: unexpected columns: {paste(extra, collapse = ', ')}")
}
if (!DBI::dbExistsTable(con2, "lifestage_review")) {
  cli::cli_abort("FAIL: lifestage_review table not created")
}

cli::cli_alert_success("Schema assertion passed -- v2.4 schema confirmed")
cli::cli_alert_success("TEAR-03 complete")
