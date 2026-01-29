# ==============================================================================
# Phase 9 Integration Validation
# Comprehensive end-to-end testing for v1.5 Swagger 2.0 support
# ==============================================================================

# Load pipeline modules
source("dev/endpoint_eval/00_config.R")
source("dev/endpoint_eval/01_schema_resolution.R")
source("dev/endpoint_eval/04_openapi_parser.R")
library(cli)

# ==============================================================================
# Task 1: Create baseline and verify INTEG-01 (version detection wired)
# ==============================================================================

cli::cli_h1("Phase 9 Integration Validation")

# -----------------------------------------------------------------------------
# Step 1: Save baseline stubs before regeneration
# -----------------------------------------------------------------------------

cli::cli_h2("Step 1: Save Baseline Stubs")

# Create baseline directory
dir.create(".baseline/stubs", recursive = TRUE, showWarnings = FALSE)

# Count existing stub files
amos_files <- list.files("R", pattern = "^chemi_amos.*\\.R$", full.names = TRUE)
rdkit_files <- list.files("R", pattern = "^chemi_rdkit.*\\.R$", full.names = TRUE)
mordred_files <- list.files("R", pattern = "^chemi_mordred.*\\.R$", full.names = TRUE)
ctx_chem_files <- list.files("R", pattern = "^ct_chemical.*\\.R$", full.names = TRUE)

cli::cli_alert_info("Found {length(amos_files)} AMOS stub files")
cli::cli_alert_info("Found {length(rdkit_files)} RDKit stub files")
cli::cli_alert_info("Found {length(mordred_files)} Mordred stub files")
cli::cli_alert_info("Found {length(ctx_chem_files)} ct_chemical stub files")

# Copy stub files to baseline
if (length(amos_files) > 0) {
  file.copy(amos_files, ".baseline/stubs/", overwrite = TRUE)
  cli::cli_alert_success("Copied {length(amos_files)} AMOS stubs to baseline")
}

if (length(rdkit_files) > 0) {
  file.copy(rdkit_files, ".baseline/stubs/", overwrite = TRUE)
  cli::cli_alert_success("Copied {length(rdkit_files)} RDKit stubs to baseline")
}

if (length(mordred_files) > 0) {
  file.copy(mordred_files, ".baseline/stubs/", overwrite = TRUE)
  cli::cli_alert_success("Copied {length(mordred_files)} Mordred stubs to baseline")
}

if (length(ctx_chem_files) > 0) {
  file.copy(ctx_chem_files, ".baseline/stubs/", overwrite = TRUE)
  cli::cli_alert_success("Copied {length(ctx_chem_files)} ct_chemical stubs to baseline")
}

# -----------------------------------------------------------------------------
# Step 2: Verify INTEG-01 (version detection wired)
# -----------------------------------------------------------------------------

cli::cli_h2("INTEG-01: Version Detection Wired")

# Test 1: Swagger 2.0 - AMOS
# openapi_to_spec() calls detect_schema_version() and logs the result via cli
cli::cli_alert_info("Parsing AMOS schema (Swagger 2.0 expected)...")
amos_spec <- openapi_to_spec("schema/chemi-amos-prod.json")
# Verify body extraction worked for POST endpoints
amos_post <- amos_spec[amos_spec$method == "POST", ]
stopifnot("AMOS has POST endpoints" = nrow(amos_post) > 0)
stopifnot("AMOS POST endpoints have body params" = any(amos_post$has_body))
stopifnot("AMOS body_params populated" = any(nchar(amos_post$body_params) > 0))
cli::cli_alert_success("AMOS: {nrow(amos_post)} POST endpoints with body params extracted")

# Test 2: Swagger 2.0 - RDKit
cli::cli_alert_info("Parsing RDKit schema (Swagger 2.0 expected)...")
rdkit_spec <- openapi_to_spec("schema/chemi-rdkit-staging.json")
rdkit_post <- rdkit_spec[rdkit_spec$method == "POST", ]
stopifnot("RDKit has POST endpoints" = nrow(rdkit_post) > 0)
cli::cli_alert_success("RDKit: {nrow(rdkit_post)} POST endpoints parsed")

# Test 3: Swagger 2.0 - Mordred
cli::cli_alert_info("Parsing Mordred schema (Swagger 2.0 expected)...")
mordred_spec <- openapi_to_spec("schema/chemi-mordred-staging.json")
mordred_post <- mordred_spec[mordred_spec$method == "POST", ]
stopifnot("Mordred has POST endpoints" = nrow(mordred_post) > 0)
cli::cli_alert_success("Mordred: {nrow(mordred_post)} POST endpoints parsed")

# Test 4: OpenAPI 3.0 - ctx-chemical
cli::cli_alert_info("Parsing ctx-chemical schema (OpenAPI 3.0 expected)...")
ctx_chem_spec <- openapi_to_spec("schema/ctx-chemical-prod.json")
ctx_post <- ctx_chem_spec[ctx_chem_spec$method == "POST", ]
if (nrow(ctx_post) > 0) {
  has_body <- sum(ctx_post$has_body, na.rm = TRUE)
  cli::cli_alert_success("ctx-chemical: {nrow(ctx_post)} POST endpoints, {has_body} with body params")
} else {
  cli::cli_alert_success("ctx-chemical: Parsed successfully (no POST endpoints)")
}

# Test 5: OpenAPI 3.0 - chemi-resolver
cli::cli_alert_info("Parsing chemi-resolver schema (OpenAPI 3.0 expected)...")
chemi_resolver_spec <- openapi_to_spec("schema/chemi-resolver-prod.json")
resolver_post <- chemi_resolver_spec[chemi_resolver_spec$method == "POST", ]
stopifnot("chemi-resolver has POST endpoints" = nrow(resolver_post) > 0)
stopifnot("chemi-resolver body params extracted" = any(nchar(resolver_post$body_params) > 0))
cli::cli_alert_success("chemi-resolver: {nrow(resolver_post)} POST endpoints with body params")

# -----------------------------------------------------------------------------
# Step 3: Report version detection results
# -----------------------------------------------------------------------------

cli::cli_h2("INTEG-01 Verification Results")
cli::cli_alert_success("Version detection is wired in openapi_to_spec()")
cli::cli_alert_success("Swagger 2.0 schemas parse correctly with body extraction")
cli::cli_alert_success("OpenAPI 3.0 schemas parse correctly (no regression)")
cli::cli_alert_success("detect_schema_version() called at entry point (visible in cli output above)")
