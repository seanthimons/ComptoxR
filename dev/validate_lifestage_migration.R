validate_lifestage_migration <- function() {
  Sys.setenv(COMPTOXR_CRAN_SAFE_TESTS = 'true', NOT_CRAN = 'false')
  Sys.unsetenv('ctx_api_key')
  devtools::test(
    filter = 'eco_functions|ecotox_source_only|cran_tarball_test_paths',
    reporter = 'summary',
    stop_on_failure = TRUE
  )
  build_lifestage_package()
}

build_lifestage_package <- function() {
  library <- file.path(normalizePath('.migration-evidence', winslash = '/'), 'comptoxr-library')
  dir.create(library, recursive = TRUE, showWarnings = FALSE)
  archive <- pkgbuild::build(dest_path = '.migration-evidence', vignettes = FALSE, manual = FALSE)
  contents <- utils::untar(archive, list = TRUE)
  stopifnot('ComptoxR/inst/ecotox/ecotox_build.R' %in% contents)
  stopifnot(
    !any(grepl('eco_lifestage_patch[.]R|lifestage_patch_seed[.]csv|HANDOFF[.]md|migration-plan[.]md', contents))
  )
  utils::install.packages(archive, repos = NULL, type = 'source', lib = library)
  invisible(list(archive = archive, library = library))
}

if (sys.nframe() == 0L) {
  validate_lifestage_migration()
}
