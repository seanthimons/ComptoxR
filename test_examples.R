# Test script focusing on endpoints with examples
library(tidyverse)
library(jsonlite)
source("endpoint_eval_utils.R")

ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Load schema
openapi <- jsonlite::fromJSON(here::here('schema', 'ctx_chemical_prod.json'), simplifyVector = FALSE)
endpoints <- openapi_to_spec(openapi)

cat("=== Testing Endpoints with Path Parameter Examples ===\n\n")

# Find listName endpoint (we know it has an example)
list_endpoint <- endpoints %>%
  filter(str_detect(route, "list.*by-name")) %>%
  mutate(
    batch_limit = 1,
    file = "ct_chemical_list_by_name.R"
  )

if (nrow(list_endpoint) > 0) {
  cat("1. List Endpoint (listName parameter)\n")
  cat("   Example from schema:", list_endpoint$path_param_metadata[[1]]$listName$example, "\n")
  cat("   Description:", list_endpoint$path_param_metadata[[1]]$listName$description, "\n\n")

  result <- render_endpoint_stubs(list_endpoint, config = ct_config)
  cat("Generated stub:\n")
  cat(result$text[1])
  cat("\n")
}

# Find formula endpoint (GET with path param)
cat("\n2. Formula Endpoint (GET with path param)\n")
formula_endpoint <- endpoints %>%
  filter(str_detect(route, "chemical.*by-formula"), method == "GET") %>%
  slice(1) %>%
  mutate(
    batch_limit = 1,
    file = "ct_chemical_by_formula.R"
  )

if (nrow(formula_endpoint) > 0) {
  cat("   Path params:", formula_endpoint$path_params, "\n")
  if (length(formula_endpoint$path_param_metadata[[1]]) > 0) {
    param_name <- names(formula_endpoint$path_param_metadata[[1]])[1]
    cat("   Example:", formula_endpoint$path_param_metadata[[1]][[param_name]]$example, "\n")
    cat("   Description:", formula_endpoint$path_param_metadata[[1]][[param_name]]$description, "\n\n")

    result <- render_endpoint_stubs(formula_endpoint, config = ct_config)
    cat("Generated stub:\n")
    cat(result$text[1])
  } else {
    cat("   No metadata found\n")
  }
  cat("\n")
}

# Find DTXSID endpoint with query params
cat("\n3. DTXSID Endpoint with Query Parameters\n")
dtxsid_endpoint <- endpoints %>%
  filter(str_detect(route, "by-dtxsid"), query_params != "") %>%
  slice(1) %>%
  mutate(
    batch_limit = 200,
    file = "ct_chemical_dtxsid_search.R"
  )

if (nrow(dtxsid_endpoint) > 0) {
  cat("   Query params:", dtxsid_endpoint$query_params, "\n")
  if (length(dtxsid_endpoint$query_param_metadata[[1]]) > 0) {
    for (param_name in names(dtxsid_endpoint$query_param_metadata[[1]])) {
      meta <- dtxsid_endpoint$query_param_metadata[[1]][[param_name]]
      cat("   -", param_name, ":", meta$description, "\n")
    }

    result <- render_endpoint_stubs(dtxsid_endpoint, config = ct_config)
    cat("\nGenerated stub:\n")
    cat(result$text[1])
  } else {
    cat("   No metadata found\n")
  }
}

cat("\n=== All example tests completed ===\n")
