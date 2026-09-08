check_endpoint_artifacts <- function() {
  Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false')
  source('dev/validate_lifestage_migration.R')
  source('dev/check_public_api.R')
  built <- build_lifestage_package()
  expanded <- tempfile('expanded-source-')
  dir.create(expanded)
  on.exit(unlink(expanded, recursive = TRUE), add = TRUE)
  utils::untar(built$archive, exdir = expanded)
  check_public_api(file.path(expanded, 'ComptoxR'), membership = FALSE)
  result <- rcmdcheck::rcmdcheck(
    built$archive,
    args = '--no-manual',
    error_on = 'warning',
    check_dir = '.migration-evidence/endpoint-check'
  )
  stopifnot(!length(result$errors), !length(result$warnings), !length(result$notes))
  invisible(built)
}
if (sys.nframe() == 0L) {
  check_endpoint_artifacts()
}
