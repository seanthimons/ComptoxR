# Test script to demonstrate the new parameter handling in render_stubs
library(tibble)
library(dplyr)

# Source the helper functions
source("endpoint eval.R")

# Create test data with different parameter scenarios
test_spec <- tibble(
  route = c(
    "hazard/search",
    "chemical/detail",
    "exposure/list"
  ),
  method = c("POST", "GET", "GET"),
  summary = c(
    "Search hazard data",
    "Get chemical details",
    "List exposure records"
  ),
  has_body = c(TRUE, FALSE, FALSE),
  params = c(
    "projection,format,limit",  # Multiple params
    "",                          # No params
    "filter"                     # Single param
  ),
  file = c(
    "ct_hazard_search.R",
    "ct_chemical_detail.R",
    "ct_exposure_list.R"
  ),
  batch_limit = c(200, 1, 1)
)

# Generate stubs
result <- render_stubs(test_spec, example_query = "DTXSID7020182")

# Print the generated code for inspection
cat("\n========== Example 1: Endpoint WITH multiple parameters ==========\n")
cat(result$text[1])

cat("\n\n========== Example 2: Endpoint WITHOUT parameters ==========\n")
cat(result$text[2])

cat("\n\n========== Example 3: Endpoint WITH single parameter ==========\n")
cat(result$text[3])
