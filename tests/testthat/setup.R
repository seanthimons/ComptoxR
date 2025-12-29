# Global test configuration
library(testthat)

# Set up dummy environment variables for tests
# This ensures tests can run even if the user hasn't set up their keys locally
Sys.setenv("ctx_api_key" = Sys.getenv("ctx_api_key", "dummy_ctx_key"))
Sys.setenv("batch_limit" = "100")
Sys.setenv("run_debug" = "FALSE")
Sys.setenv("run_verbose" = "FALSE")

# Explicitly set servers to Production for tests
# This ensures consistency across different developer environments
ctx_server(1)
chemi_server(1)
epi_server(1)

# Standard DTXSID for connectivity tests
test_dtxsid <- "DTXSID7020182" # Benzene
