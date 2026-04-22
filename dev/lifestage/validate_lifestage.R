#!/usr/bin/env Rscript

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

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

ecotox_release <- .eco_lifestage_release_id(con)
org_lifestages <- DBI::dbGetQuery(
  con,
  "SELECT DISTINCT description FROM lifestage_codes ORDER BY description"
)$description

cli::cli_h1("Lifestage Validation")
cli::cli_alert_info("DB: {.path {db_path}}")
cli::cli_alert_info("Release: {ecotox_release}")
cli::cli_alert_info("Distinct lifestage terms: {length(org_lifestages)}")

materialized <- .eco_lifestage_materialize_tables(
  org_lifestages = org_lifestages,
  ecotox_release = ecotox_release,
  refresh = "auto",
  force = FALSE,
  write_cache = FALSE
)

review_counts <- materialized$review |>
  count(review_status, sort = TRUE)

cli::cli_alert_success("Dictionary rows: {nrow(materialized$dictionary)}")
cli::cli_alert_info("Review rows: {nrow(materialized$review)}")

if (nrow(review_counts) > 0) {
  cli::cli_h2("Review Breakdown")
  print(review_counts)
}

if (nrow(materialized$review) > 0) {
  cli::cli_h2("Quarantined Terms")
  print(
    materialized$review |>
      distinct(org_lifestage, review_status) |>
      arrange(org_lifestage)
  )
}
