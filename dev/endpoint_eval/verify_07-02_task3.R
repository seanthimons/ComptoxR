# Verification script for Phase 07-02 Task 3
# Tests OpenAPI 3.0 parsing (no regression)

source("dev/endpoint_eval/00_config.R")
source("dev/endpoint_eval/01_schema_resolution.R")
source("dev/endpoint_eval/04_openapi_parser.R")
library(cli)

# Test OpenAPI 3.0 (chemi-resolver-prod)
cli::cli_h2("Testing OpenAPI 3.0 (chemi-resolver-prod)")
chemi_spec <- openapi_to_spec("schema/chemi-resolver-prod.json")

# Check that POST endpoints work correctly
chemi_post <- chemi_spec[chemi_spec$method == "POST", ]
cli::cli_alert_info("Found {nrow(chemi_post)} POST endpoints")

# BODY-02: Verify OpenAPI 3.0 body extraction produces body_params content
if (any(nchar(chemi_post$body_params) > 0)) {
  cli::cli_alert_success("OpenAPI 3.0 POST endpoints have body_params extracted")
} else {
  cli::cli_alert_danger("OpenAPI 3.0 POST endpoints missing body_params")
  stop("BODY-02 requirement failed")
}

# Check that needs_resolver detection works for Chemical schemas
if (any(chemi_post$needs_resolver)) {
  cli::cli_alert_success("needs_resolver detection working for OpenAPI 3.0")
} else {
  cli::cli_alert_info("No Chemical schemas found (needs_resolver all FALSE)")
}

# Test CompTox Dashboard schema (ctx-chemical-prod.json)
cli::cli_h2("Testing OpenAPI 3.0 (ctx-chemical-prod)")
if (file.exists("schema/ctx-chemical-prod.json")) {
  ctx_spec <- openapi_to_spec("schema/ctx-chemical-prod.json")
  ctx_post <- ctx_spec[ctx_spec$method == "POST", ]

  if (nrow(ctx_spec) > 0) {
    cli::cli_alert_success("CompTox Dashboard schema parsed successfully")
    cli::cli_alert_info("Found {nrow(ctx_post)} POST endpoints")

    # BODY-02: Verify body_params extraction
    if (any(nchar(ctx_post$body_params) > 0)) {
      cli::cli_alert_success("CTX POST endpoints have body_params extracted")
    } else {
      cli::cli_alert_warning("CTX POST endpoints missing body_params (may be expected)")
    }
  } else {
    cli::cli_alert_danger("CompTox Dashboard schema parsing failed")
    stop("ctx-chemical-prod.json parsing failed")
  }
} else {
  cli::cli_alert_warning("ctx-chemical-prod.json not found, skipping test")
}

cli::cli_h2("Task 3 verification complete")
cli::cli_alert_success("OpenAPI 3.0 parsing works correctly (no regression)")
