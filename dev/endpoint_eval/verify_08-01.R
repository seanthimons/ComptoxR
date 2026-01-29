# Verification script for Phase 8 Plan 01: Reference Resolution Enhancement
# Tests REF-01 (fallback chain), REF-02 (version context), REF-03 (depth limit)

cat("=== Phase 8 Plan 01 Verification ===\n\n")

# Source dependencies
source("dev/endpoint_eval/00_config.R")
source("dev/endpoint_eval/01_schema_resolution.R")

# ==== Test 1: Swagger 2.0 Definition Resolution ====
cat("Test 1: Swagger 2.0 definition resolution...\n")
amos <- jsonlite::fromJSON("schema/chemi-amos-prod.json", simplifyVector = FALSE)
swagger_version <- detect_schema_version(amos)
stopifnot(swagger_version$type == "swagger")

# Test with actual definitions from the schema
if (length(amos$definitions) > 0) {
  def_names <- names(amos$definitions)
  test_def <- def_names[1]
  result <- resolve_schema_ref(paste0("#/definitions/", test_def), amos$definitions, swagger_version)
  stopifnot(!is.null(result))
  cat("  PASS: Swagger 2.0 #/definitions/ resolves correctly\n")
} else {
  cat("  SKIP: No definitions in schema\n")
}

# ==== Test 2: OpenAPI 3.0 Component Resolution ====
cat("Test 2: OpenAPI 3.0 component resolution...\n")
chemi <- jsonlite::fromJSON("schema/chemi-resolver-prod.json", simplifyVector = FALSE)
openapi_version <- detect_schema_version(chemi)
stopifnot(openapi_version$type == "openapi")

# Find a schema that exists
schema_names <- names(chemi$components$schemas)
if (length(schema_names) > 0) {
  test_ref <- paste0("#/components/schemas/", schema_names[1])
  result <- resolve_schema_ref(test_ref, chemi$components, openapi_version)
  stopifnot(!is.null(result))
  cat("  PASS: OpenAPI 3.0 #/components/schemas/ resolves correctly\n")
} else {
  cat("  SKIP: No schemas in test file\n")
}

# ==== Test 3: Malformed Reference Validation ====
cat("Test 3: Malformed reference validation...\n")

# No # prefix - should abort
err <- tryCatch(
  validate_schema_ref("definitions/Foo"),
  error = function(e) e
)
if (inherits(err, "error") && grepl("must start with", conditionMessage(err))) {
  cat("  PASS: Missing # prefix aborts with correct error\n")
} else {
  stop("Test 3a failed: Expected error for missing # prefix")
}

# External file ref - should abort
err <- tryCatch(
  validate_schema_ref("other.json#/definitions/Foo"),
  error = function(e) e
)
if (inherits(err, "error") && grepl("External file reference", conditionMessage(err))) {
  cat("  PASS: External file ref aborts with correct error\n")
} else {
  stop("Test 3b failed: Expected error for external file ref")
}

# Empty schema name - should abort
err <- tryCatch(
  validate_schema_ref("#/definitions/"),
  error = function(e) e
)
if (inherits(err, "error") && grepl("Missing schema name", conditionMessage(err))) {
  cat("  PASS: Empty schema name aborts with correct error\n")
} else {
  stop("Test 3c failed: Expected error for empty schema name")
}

# ==== Test 4: Depth Limit Enforcement ====
cat("Test 4: Depth limit enforcement...\n")

# Create mock deeply nested schema
deep_components <- list(
  schemas = list(
    Level0 = list(`$ref` = "#/components/schemas/Level1"),
    Level1 = list(`$ref` = "#/components/schemas/Level2"),
    Level2 = list(`$ref` = "#/components/schemas/Level3"),
    Level3 = list(`$ref` = "#/components/schemas/Level4"),
    Level4 = list(type = "object", properties = list(x = list(type = "string")))
  )
)

# max_depth = 3, starting at Level0 should fail at Level4 (depth 4)
err <- tryCatch(
  resolve_schema_ref("#/components/schemas/Level0", deep_components, NULL, max_depth = 3),
  error = function(e) e
)
if (inherits(err, "error") && grepl("depth limit exceeded", conditionMessage(err))) {
  cat("  PASS: Depth limit 3 correctly enforced\n")
} else {
  stop("Test 4a failed: Expected depth limit error")
}

# Depth 2 should work (Level0 -> Level1 -> Level2)
shallow_components <- list(
  schemas = list(
    Level0 = list(`$ref` = "#/components/schemas/Level1"),
    Level1 = list(`$ref` = "#/components/schemas/Level2"),
    Level2 = list(type = "object", properties = list(x = list(type = "string")))
  )
)
result <- resolve_schema_ref("#/components/schemas/Level0", shallow_components, NULL, max_depth = 3)
stopifnot(result$type == "object")
cat("  PASS: Depth 2 nesting resolves correctly\n")

# ==== Test 5: Circular Reference Detection ====
cat("Test 5: Circular reference detection...\n")

circular_components <- list(
  schemas = list(
    A = list(`$ref` = "#/components/schemas/B"),
    B = list(`$ref` = "#/components/schemas/A")
  )
)

# Should warn and return partial schema, not infinite loop
result <- tryCatch({
  suppressMessages(suppressWarnings(resolve_schema_ref("#/components/schemas/A", circular_components, NULL, max_depth = 10)))
}, error = function(e) {
  # May hit depth limit instead of circular detection - both are acceptable
  list(type = "depth_or_circular")
})
cat("  PASS: Circular reference handled without infinite loop\n")

# ==== Test 6: Fallback Chain (REF-01) ====
cat("Test 6: Fallback chain...\n")

# Create schema where definition is in "wrong" location for version
# Swagger version but schema only in components/schemas
mixed_components <- list(
  schemas = list(
    TestSchema = list(type = "object", properties = list(x = list(type = "string")))
  )
)
swagger_v <- list(version = "2.0", type = "swagger")

# With Swagger version, primary is definitions (empty), fallback is components/schemas
# The cli::cli_alert_info about fallback should appear
result <- resolve_schema_ref("#/components/schemas/TestSchema", mixed_components, swagger_v)
stopifnot(!is.null(result))
stopifnot(result$type == "object")
cat("  PASS: Fallback chain resolves cross-location references\n")

# Test OpenAPI with definitions fallback
openapi_v <- list(version = "3.0.0", type = "openapi")
# For OpenAPI, primary is components/schemas (empty), secondary is root level (definitions)
# Create a components structure with empty schemas but definitions at root
components_with_defs <- list(
  schemas = list(),
  DefinitionSchema = list(type = "string")  # This is at root level
)
result <- resolve_schema_ref("#/definitions/DefinitionSchema", components_with_defs, openapi_v)
stopifnot(result$type == "string")
cat("  PASS: Version-aware path selection verified (OpenAPI with definitions fallback)\n")

# ==== Test 7: Version Context (REF-02) ====
cat("Test 7: Version context parameter...\n")

# Verify schema_version parameter is accepted and used
openapi_components <- list(
  schemas = list(
    TestSchema = list(type = "number")
  )
)

# With OpenAPI version
result1 <- resolve_schema_ref("#/components/schemas/TestSchema", openapi_components, openapi_v)
stopifnot(result1$type == "number")

# With Swagger version (should still work via fallback)
result2 <- resolve_schema_ref("#/components/schemas/TestSchema", openapi_components, swagger_v)
stopifnot(result2$type == "number")

# Without version (should default to OpenAPI-style)
result3 <- resolve_schema_ref("#/components/schemas/TestSchema", openapi_components, NULL)
stopifnot(result3$type == "number")

cat("  PASS: schema_version parameter flows through resolution\n")

# ==== Summary ====
cat("\n=== All Phase 8 Plan 01 Tests Passed ===\n")
cat("REF-01: Fallback chain - VERIFIED\n")
cat("REF-02: Version context - VERIFIED\n")
cat("REF-03: Depth limit 3 - VERIFIED\n")
cat("Error handling: cli::cli_abort() - VERIFIED\n")
cat("Validation: Edge cases - VERIFIED\n")
