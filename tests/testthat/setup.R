# Global test configuration
library(testthat)
library(ComptoxR)

# Set up dummy environment variables for tests
# This ensures tests can run even if the user hasn't set up their keys locally
Sys.setenv("ctx_api_key" = Sys.getenv("ctx_api_key", "dummy_ctx_key"))
Sys.setenv("batch_limit" = "100")
Sys.setenv("run_debug" = "FALSE")
Sys.setenv("run_verbose" = "FALSE")

# Explicitly set servers to Production for tests
# This ensures consistency across different developer environments
# Set server URLs directly as environment variables
Sys.setenv("ctx_burl" = "https://api-ccte.epa.gov/")
Sys.setenv("chemi_burl" = "https://hcd.rtpnc.epa.gov/api")
Sys.setenv("epi_burl" = "https://episuite.dev/EpiWebSuite/api")
Sys.setenv("eco_burl" = "https://cfpub.epa.gov/ecotox/index.cfm")

# Standard DTXSID for connectivity tests
test_dtxsid <- "DTXSID7020182" # Benzene
