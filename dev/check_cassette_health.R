#!/usr/bin/env Rscript
# Check cassette health: safety, errors, parse validity

library(cli)

# Source helper functions
source(here::here("tests/testthat/helper-vcr.R"))

cli_h1("VCR Cassette Health Check")

# Check 1: API key leaks
cli_h2("Checking for API key leaks")
safety_issues <- check_cassette_safety()

# Check 2: HTTP error responses
cli_h2("Checking for HTTP error responses")
error_cassettes <- check_cassette_errors(delete = FALSE)

# Check 3: Parse validity (can YAML be read?)
cli_h2("Checking YAML parse validity")
fixtures_dir <- here::here("tests/testthat/fixtures")
cassettes <- list.files(fixtures_dir,
                       pattern = "\\.yml$",
                       full.names = TRUE)

parse_errors <- list()
for (cassette in cassettes) {
  tryCatch({
    yaml::read_yaml(cassette)
  }, error = function(e) {
    parse_errors[[basename(cassette)]] <<- e$message
  })
}

if (length(parse_errors) > 0) {
  cli_alert_danger("Found {length(parse_errors)} cassettes with parse errors")
  for (name in names(parse_errors)) {
    cli_alert_warning("{name}: {parse_errors[[name]]}")
  }
} else {
  cli_alert_success("All cassettes parse successfully")
}

# Summary
cli_rule()
total_cassettes <- length(cassettes)
cli_alert_info("Total cassettes: {total_cassettes}")
cli_alert_info("Safety issues: {length(safety_issues)}")
cli_alert_info("Error responses: {nrow(error_cassettes)}")
cli_alert_info("Parse errors: {length(parse_errors)}")

if (length(safety_issues) == 0 &&
    nrow(error_cassettes) == 0 &&
    length(parse_errors) == 0) {
  cli_alert_success("All health checks passed!")
  quit(status = 0)
} else {
  cli_alert_danger("Health checks failed - review issues above")
  quit(status = 1)
}
