# Offline publication checks; callable with source() from the project root.
validate_migration_release <- function() {
  checks <- new.env(parent = globalenv())
  sys.source('dev/db_smoke_check.R', checks)
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ':memory:')
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  fails <- function() inherits(try(checks$.smoke_source_only_ecotox(con), silent = TRUE), 'try-error')
  stopifnot(fails())
  DBI::dbWriteTable(con, 'lifestage_codes', data.frame(code = 'JU'))
  stopifnot(isTRUE(checks$.smoke_source_only_ecotox(con)))
  for (table in c('lifestage_dictionary', 'lifestage_review')) {
    DBI::dbWriteTable(con, table, data.frame(value = 'derived'))
    stopifnot(fails())
    DBI::dbRemoveTable(con, table)
  }
  sys.source('R/z_db_version.R', checks)
  stopifnot(checks$.db_rebuild_needed('same', 'same', force = TRUE)$needed)
  message('Source-only publication and forced same-release rebuild checks passed.')
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  validate_migration_release()
}
