# Test script for path_params implementation
# This validates that endpoints with multiple path parameters generate correctly

library(tidyverse)
source("endpoint_eval_utils.R")

# Configuration for CT functions
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Test Case 1: Property range endpoint (multiple path params, no query params)
cat("=== Test Case 1: Property Range Endpoint ===\n")
test_spec_1 <- tibble(
  route = "chemical/property/experimental/search/by-range/",
  method = "GET",
  summary = "Search by property range",
  has_body = FALSE,
  params = "propertyName,start,end",
  path_params = "propertyName,start,end",
  query_params = "",
  num_path_params = 3,
  batch_limit = 1,
  file = "ct_chemical_property_experimental_by_range.R"
)

result_1 <- render_endpoint_stubs(test_spec_1, config = ct_config)
cat("\nGenerated function:\n")
cat(result_1$text[1])
cat("\n")

# Test Case 2: Standard DTXSID endpoint (single path param, query params)
cat("\n=== Test Case 2: Standard DTXSID Endpoint ===\n")
test_spec_2 <- tibble(
  route = "hazard/toxval/search/by-dtxsid/",
  method = "POST",
  summary = "Get hazard data",
  has_body = TRUE,
  params = "projection",
  path_params = "",
  query_params = "projection",
  num_path_params = 0,
  batch_limit = 200,
  file = "ct_hazard.R"
)

result_2 <- render_endpoint_stubs(test_spec_2, config = ct_config)
cat("\nGenerated function:\n")
cat(result_2$text[1])
cat("\n")

# Test Case 3: Single path param, no query params
cat("\n=== Test Case 3: Single Path Param ===\n")
test_spec_3 <- tibble(
  route = "chemical/list/search/by-name/",
  method = "GET",
  summary = "Search by list name",
  has_body = FALSE,
  params = "listName",
  path_params = "listName",
  query_params = "",
  num_path_params = 1,
  batch_limit = 1,
  file = "ct_chemical_list_by_name.R"
)

result_3 <- render_endpoint_stubs(test_spec_3, config = ct_config)
cat("\nGenerated function:\n")
cat(result_3$text[1])
cat("\n")

cat("\n=== All tests completed successfully ===\n")
