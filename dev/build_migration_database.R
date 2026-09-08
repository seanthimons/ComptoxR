# Build from frozen EPA files in an isolated data directory. No user DB is opened.
build_migration_database <- function(builder = 'data-raw/ecotox.R', build_name = 'source-only-build') {
  input <- normalizePath('.migration-evidence/ecotox-release-inputs', mustWork = TRUE)
  stopifnot(build_name %in% c('source-only-build', 'source-only-installed'))
  output <- file.path(normalizePath('.migration-evidence', mustWork = TRUE), build_name)
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  withr::local_envvar(c(R_USER_DATA_DIR = output, COMPTOXR_ECOTOX_RELEASE_ZIP = 'ecotox_ascii_06_11_2026.zip'))
  expected <- file.path(output, 'R', 'ComptoxR')
  stopifnot(identical(tools::R_user_dir('ComptoxR', 'data'), expected))
  if (file.exists(file.path(expected, 'ecotox.duckdb'))) {
    stop('Use the existing build evidence; do not overwrite it.')
  }
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      stopifnot(identical(req$url, 'https://gaftp.epa.gov/ecotox/'))
      httr2::response(
        status_code = 200L,
        body = readBin(file.path(input, 'index.html'), 'raw', n = file.info(file.path(input, 'index.html'))$size)
      )
    },
    .package = 'httr2'
  )
  env <- new.env(parent = globalenv())
  env$download.file <- function(url, destfile, ...) {
    source <- file.path(input, basename(url))
    stopifnot(file.exists(source), file.copy(source, destfile))
    0L
  }
  build_warnings <- character()
  withCallingHandlers(sys.source(builder, env), warning = function(warning) {
    build_warnings <<- c(build_warnings, conditionMessage(warning))
    invokeRestart('muffleWarning')
  })
  writeLines(build_warnings, file.path('dev/reports/migration', paste0(build_name, '-warnings.txt')))
  withr::local_envvar(c(DB_NAME = 'ecotox', DB_PATH = file.path(expected, 'ecotox.duckdb')))
  smoke <- new.env(parent = globalenv())
  sys.source('dev/db_smoke_check.R', smoke)
  smoke$.smoke_check()
  paths <- c(list.files(input, full.names = TRUE), list.files(expected, full.names = TRUE))
  hashes <- data.frame(
    path = basename(paths),
    sha256 = vapply(paths, function(path) digest::digest(file = path, algo = 'sha256'), character(1))
  )
  utils::write.csv(hashes, file.path('dev/reports/migration', paste0(build_name, '-hashes.csv')), row.names = FALSE)
  invisible(file.path(expected, 'ecotox.duckdb'))
}

if (sys.nframe() == 0L) {
  build_migration_database()
}
