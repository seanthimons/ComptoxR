# Setup file for test configuration and vcr
# This file runs once before all tests

library(vcr)
library(here)

# Check if we need to record cassettes (first run or re-recording)
cassette_dir <- here('tests', 'testthat', 'fixtures')
has_cassettes <- length(list.files(cassette_dir, pattern = "\\.yml$")) > 0

# Configure vcr to hit production servers on first run, then use cassettes
vcr_configure(
  dir = cassette_dir,
  record = "once",  # Record on first run when cassette doesn't exist, then replay
  match_requests_on = c("method", "uri", "body_json"),  # Match requests precisely
  filter_sensitive_data = list(
    # Replace actual API key with placeholder in cassettes
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
  ),
  filter_request_headers = list(
    # Remove sensitive headers from recordings
    `x-api-key` = "<<<API_KEY>>>"
  ),
  preserve_exact_body_bytes = FALSE
)

# Set up test environment variables
if (!has_cassettes && Sys.getenv("ctx_api_key") == "") {
  # First run requires real API key to record cassettes
  stop(
    "No cassettes found and no API key set. ",
    "For the first test run, you must set ctx_api_key to record cassettes from production: ",
    "Sys.setenv(ctx_api_key = 'YOUR_API_KEY')"
  )
} else if (has_cassettes && Sys.getenv("ctx_api_key") == "") {
  # Subsequent runs can use placeholder when cassettes exist
  Sys.setenv(ctx_api_key = "test_api_key_placeholder")
  message("Using cached vcr cassettes (no API key needed)")
} else {
  message("Using production API with key: ", substr(Sys.getenv("ctx_api_key"), 1, 8), "...")
}

if (Sys.getenv("ctx_burl") == "") {
  # Set default base URL if not already set
  ctx_server(1)
}

if (Sys.getenv("batch_limit") == "") {
  # Set default batch limit for testing
  Sys.setenv(batch_limit = "200")
}

# Turn off verbose output during tests unless explicitly enabled
if (Sys.getenv("run_verbose") == "") {
  invisible(Sys.setenv(run_verbose = "TRUE"))
}
if (Sys.getenv("run_debug") == "") {
  invisible(Sys.setenv(run_debug = "FALSE"))
}
