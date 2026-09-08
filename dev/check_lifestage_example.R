check_lifestage_example <- function() {
  root <- normalizePath('.migration-evidence', winslash = '/')
  .libPaths(c(file.path(root, 'comptoxr-library'), file.path(root, 'harmonizer-library'), .libPaths()))
  loadNamespace('ComptoxR')
  loadNamespace('envharmonizer')
  old <- setwd(tempdir())
  on.exit(setwd(old))
  db_path <- file.path(root, 'source-only-build/R/ComptoxR/ecotox.duckdb')
  ComptoxR::eco_server(db_path)
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  release <- DBI::dbGetQuery(con, "SELECT value FROM _metadata WHERE key = 'ecotox_release'")$value
  results <- ComptoxR::eco_results(casrn = '50-29-3', eco_group = 'Fish', endpoint = c('LC50', 'EC50'), con = con)
  stopifnot(nrow(results) > 0L, !any(c('harmonized_life_stage', 'reproductive_stage') %in% names(results)))
  explicit <- envharmonizer::harmonize_lifestage(results, release)
  stopifnot(identical(explicit[names(results)], results), nrow(explicit) == nrow(results))
  native <- DBI::dbReadTable(con, 'lifestage_codes')$description
  dictionary <- envharmonizer::lifestage_dictionary(release)
  review <- envharmonizer::lifestage_review(release)
  unknown <- setdiff(native, c(dictionary$org_lifestage, review$org_lifestage))
  writeLines(
    c(
      paste('release:', release),
      paste('result rows:', nrow(results)),
      paste('unaccounted native descriptions:', length(unknown)),
      unknown
    ),
    file.path(root, 'lifestage-example.txt')
  )
  cat('Installed source-only query and explicit harmonization passed for', nrow(results), 'rows.\n')
  invisible(explicit)
}

if (sys.nframe() == 0L) {
  check_lifestage_example()
}
