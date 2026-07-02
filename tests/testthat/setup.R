# Global test configuration
library(testthat)
# Only load if nothing has loaded the package yet. Under
# test_dir(load_package = "source") / devtools::test the namespace is already
# live; a second devtools::load_all() here rebuilds it mid-suite and detaches the
# attached env, after which local_mocked_bindings() can no longer intercept
# unqualified internal calls (see helper-generated-contracts.R for the same trap).
if (!isNamespaceLoaded("ComptoxR")) {
  if (nzchar(Sys.getenv("GITHUB_ACTIONS"))) {
    pkgload::load_all()
  } else {
    library(ComptoxR)
  }
}

# Set up dummy environment variables for tests
# This ensures tests can run even if the user hasn't set up their keys locally
Sys.setenv("ctx_api_key" = Sys.getenv("ctx_api_key", "dummy_ctx_key"))
Sys.setenv("batch_limit" = "100")
Sys.setenv("run_debug" = "FALSE")
Sys.setenv("run_verbose" = "FALSE")

# Explicitly set servers to Production for tests
# This ensures consistency across different developer environments
# Set server URLs directly as environment variables
Sys.setenv("ctx_burl" = "https://comptox.epa.gov/ctx-api/")
Sys.setenv("chemi_burl" = "https://hcd.rtpnc.epa.gov/api")
Sys.setenv("epi_burl" = "https://episuite.dev/EpiWebSuite/api")
Sys.setenv("eco_burl" = "https://cfpub.epa.gov/ecotox/index.cfm")

cran_safe_tests <- tolower(trimws(Sys.getenv("COMPTOXR_CRAN_SAFE_TESTS", unset = ""))) %in% c("1", "true", "yes", "y")
cran_like_tests <- tolower(trimws(Sys.getenv("NOT_CRAN", unset = ""))) != "true"
if (cran_safe_tests || cran_like_tests) {
  missing_db_dir <- file.path(tempdir(), "comptoxr-cran-safe-missing-dbs")
  options(
    ComptoxR.dsstox_path = file.path(missing_db_dir, "dsstox.duckdb"),
    ComptoxR.ecotox_path = file.path(missing_db_dir, "ecotox.duckdb"),
    ComptoxR.toxval_path = file.path(missing_db_dir, "toxval.duckdb")
  )
}

# Standard DTXSID for connectivity tests
test_dtxsid <- "DTXSID7020182" # Benzene
