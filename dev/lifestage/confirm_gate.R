#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(dplyr)
  library(cli)
})

source("R/eco_connection.R")
source("R/eco_lifestage_patch.R")

source_db <- eco_path()
if (!file.exists(source_db)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {source_db}}.")
}

tmp_db <- tempfile(fileext = ".duckdb")
file.copy(source_db, tmp_db, overwrite = TRUE)
on.exit(unlink(tmp_db), add = TRUE)

.eco_close_con()

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = tmp_db, read_only = FALSE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

DBI::dbExecute(
  con,
  "INSERT INTO lifestage_codes (code, description) VALUES ('XT', 'Xylophage'), ('PL', 'Proto-larva')"
)
DBI::dbDisconnect(con, shutdown = TRUE)

cli::cli_h1("Lifestage Patch Smoke Check")
cli::cli_alert_info("Working copy: {.path {tmp_db}}")

result <- .eco_patch_lifestage(
  db_path = tmp_db,
  refresh = "live",
  force = FALSE
)

cli::cli_alert_success("Dictionary rows: {result$dictionary_rows}")
cli::cli_alert_info("Review rows: {result$review_rows}")

check_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = tmp_db, read_only = TRUE)
on.exit(DBI::dbDisconnect(check_con, shutdown = TRUE), add = TRUE)

review <- tibble::as_tibble(DBI::dbReadTable(check_con, "lifestage_review"))

print(
  review |>
    filter(org_lifestage %in% c("Xylophage", "Proto-larva")) |>
    arrange(org_lifestage, desc(candidate_score))
)
