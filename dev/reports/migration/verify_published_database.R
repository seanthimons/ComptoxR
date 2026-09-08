verify_published_database <- function(db, package_library, harmonizer_library, expected_version) {
  old_libraries <- .libPaths()
  on.exit(.libPaths(old_libraries), add = TRUE)
  .libPaths(c(package_library, harmonizer_library, old_libraries))
  stopifnot(as.character(utils::packageVersion('ComptoxR')) == expected_version)
  stopifnot(!'lifestage_details' %in% names(formals(ComptoxR::eco_results)))
  db <- normalizePath(db, winslash = '/', mustWork = TRUE)
  before <- digest::digest(file = db, algo = 'sha256')
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  stopifnot(!any(c('lifestage_dictionary', 'lifestage_review') %in% DBI::dbListTables(con)))
  stopifnot(DBI::dbExistsTable(con, 'lifestage_codes'))
  release <- DBI::dbGetQuery(con, "SELECT value FROM _metadata WHERE key = 'ecotox_release'")$value
  stopifnot(length(release) == 1L)
  local <- ComptoxR::eco_results(casrn = '50-29-3', eco_group = 'Fish', endpoint = c('LC50', 'EC50'), con = con)
  stopifnot(nrow(local) > 0L, is.character(local$organism_lifestage), is.character(local$org_lifestage))
  mapped <- envharmonizer::harmonize_lifestage(local, release)
  stopifnot(nrow(mapped) == nrow(local))
  for (name in names(local)) {
    stopifnot(identical(mapped[[name]], local[[name]]))
  }
  script <- system.file('plumber', 'ecotox', 'plumber.R', package = 'ComptoxR', mustWork = TRUE)
  port <- httpuv::randomPort()
  server <- callr::r_bg(
    function(db, library, script, port, version) {
      .libPaths(c(library, .libPaths()))
      stopifnot(as.character(utils::packageVersion('ComptoxR')) == version)
      options(ComptoxR.ecotox_path = db)
      plumber::pr_run(plumber::pr(script), host = '127.0.0.1', port = port)
    },
    args = list(db, package_library, script, port, expected_version)
  )
  on.exit(server$kill(), add = TRUE)
  url <- paste0('http://127.0.0.1:', port)
  ready <- FALSE
  for (attempt in seq_len(100L)) {
    ready <- tryCatch(
      {
        httr2::req_perform(httr2::req_timeout(httr2::request(paste0(url, '/health-check')), 1))
        TRUE
      },
      error = function(e) FALSE
    )
    if (ready) {
      break
    }
    if (!server$is_alive()) {
      stop(paste(server$read_error_lines(), collapse = '\n'))
    }
    Sys.sleep(0.1)
  }
  stopifnot(ready)
  withr::local_envvar(eco_burl = url)
  withr::local_options(ComptoxR.eco_burl = NULL)
  remote <- ComptoxR::eco_results(casrn = '50-29-3', eco_group = 'Fish', endpoint = c('LC50', 'EC50'))
  stopifnot(nrow(remote) == nrow(local))
  local <- local[order(local$result_id), ]
  remote <- remote[order(remote$result_id), ]
  for (name in c('result_id', 'organism_lifestage', 'org_lifestage')) {
    stopifnot(identical(as.character(remote[[name]]), as.character(local[[name]])))
  }
  stopifnot(identical(before, digest::digest(file = db, algo = 'sha256')))
  cat(sprintf(
    'Published package %s: %d native rows match restarted localhost HTTP and explicit mapping.\n',
    expected_version,
    nrow(local)
  ))
  cat('ECOTOX release:', release, '\nDatabase SHA-256:', before, '\n')
  invisible(TRUE)
}
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  stopifnot(length(args) == 4L)
  do.call(verify_published_database, as.list(args))
}
