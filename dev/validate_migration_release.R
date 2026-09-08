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
  workflow <- yaml::read_yaml('.github/workflows/db-ecotox-source-only.yml')
  steps <- workflow$jobs[['build-ecotox']]$steps
  stopifnot(identical(steps[[1]]$with$ref, 'main'))
  names <- vapply(steps, function(step) if (is.null(step$name)) '' else step$name, character(1))
  stopifnot('Fail after unsuccessful ECOTOX build' %in% names)
  stopifnot(!'Create ECOTOX vocabulary drift issue' %in% names)
  # The same rolling URL must fetch replacement bytes, even with the same source release.
  sys.source('R/z_db_download.R', checks)
  destination <- withr::local_tempfile()
  writeLines('old derived database', destination)
  downloads <- 0L
  testthat::local_mocked_bindings(
    req_perform = function(req, path = NULL, ...) {
      if (!is.null(path)) {
        downloads <<- downloads + 1L
        writeLines('source-only database', path)
      }
      httr2::response(status_code = 200L)
    },
    resp_body_json = function(...) {
      list(
        tag_name = 'db-latest',
        assets = list(list(
          name = 'ecotox.duckdb',
          browser_download_url = 'https://example.invalid/ecotox.duckdb',
          size = 1L
        ))
      )
    },
    .package = 'httr2'
  )
  checks$.db_download_release('ecotox', destination, tag = 'db-latest')
  stopifnot(downloads == 1L, identical(readLines(destination), 'source-only database'))
  message('Source-only publication and forced same-release rebuild checks passed.')
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  validate_migration_release()
}
