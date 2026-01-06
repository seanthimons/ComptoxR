# Test script for parameter metadata extraction and usage
# This validates that examples and descriptions from schemas are being used correctly

library(tidyverse)
library(jsonlite)
source("endpoint_eval_utils.R")

# Configuration for CT functions
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Load a real schema
cat("Loading ctx_chemical_prod.json schema...\n")
openapi <- jsonlite::fromJSON(here::here('schema', 'ctx_chemical_prod.json'), simplifyVector = FALSE)

# Parse endpoints
endpoints <- openapi_to_spec(openapi)

cat("\n=== Testing Metadata Extraction ===\n")
cat("Total endpoints found:", nrow(endpoints), "\n\n")

# Test Case 1: Formula endpoint (should have example)
formula_endpoint <- endpoints %>%
  filter(method != "POST", str_detect(route, "formula")) %>%
  slice(1)

if (nrow(formula_endpoint) > 0) {
  cat("Test Case 1: Formula Endpoint\n")
  cat("Route:", formula_endpoint$route, "\n")
  cat("Path params:", formula_endpoint$path_params, "\n")
  cat("Path metadata:\n")
  print(str(formula_endpoint$path_param_metadata[[1]]))
  cat("\n")
}

# Test Case 2: List endpoint (should have listName example)
list_endpoint <- endpoints %>%
  filter(str_detect(route, "list.*by-name")) %>%
  slice(1)

if (nrow(list_endpoint) > 0) {
  cat("Test Case 2: List Endpoint\n")
  cat("Route:", list_endpoint$route, "\n")
  cat("Path params:", list_endpoint$path_params, "\n")
  cat("Path metadata:\n")
  print(str(list_endpoint$path_param_metadata[[1]]))
  cat("\n")
}

# Test Case 3: Generate stub for formula endpoint
cat("\n=== Testing Stub Generation with Metadata ===\n\n")

if (nrow(formula_endpoint) > 0) {
  # Add file column
  test_spec <- formula_endpoint %>%
    mutate(
      batch_limit = 1,
      file = "ct_chemical_formula_search.R"
    )

  result <- render_endpoint_stubs(test_spec, config = ct_config)

  cat("Generated function for formula endpoint:\n")
  cat(result$text[1])
  cat("\n")
}

# Test Case 4: Query parameter with description
cat("\n=== Testing Query Parameter Descriptions ===\n\n")
hazard_endpoint <- endpoints %>%
  filter(str_detect(route, "hazard")) %>%
  filter(query_params != "") %>%
  slice(1)

if (nrow(hazard_endpoint) > 0) {
  cat("Route:", hazard_endpoint$route, "\n")
  cat("Query params:", hazard_endpoint$query_params, "\n")
  cat("Query metadata:\n")
  print(str(hazard_endpoint$query_param_metadata[[1]]))
  cat("\n")
}

cat("\n=== All metadata tests completed ===\n")
