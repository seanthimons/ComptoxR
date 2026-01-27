# Test script to debug stub generation for ct_chemical_search_equal
source(here::here("dev", "endpoint_eval_utils.R"))
library(jsonlite)
library(tidyverse)

# Load the ct_ endpoint eval configuration
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Parse the chemical schema
openapi <- jsonlite::fromJSON(here::here('schema', 'ctx_chemical_prod.json'), simplifyVector = FALSE)
spec <- openapi_to_spec(openapi)

# Filter to the specific endpoint we're debugging
equal_get <- spec %>% filter(grepl("/chemical/search/equal/\\{word\\}", route))
equal_post <- spec %>% filter(route == "/chemical/search/equal/")

cat("\n=== GET /chemical/search/equal/{word} ===\n")
cat("route:", equal_get$route, "\n")
cat("method:", equal_get$method, "\n")
cat("path_params:", equal_get$path_params, "\n")
cat("query_params:", equal_get$query_params, "\n")
cat("body_params:", equal_get$body_params, "\n")
cat("num_path_params:", equal_get$num_path_params, "\n")
cat("request_type:", equal_get$request_type, "\n")

cat("\npath_param_metadata:\n")
print(equal_get$path_param_metadata)

cat("\nquery_param_metadata:\n")
print(equal_get$query_param_metadata)

cat("\n=== POST /chemical/search/equal/ ===\n")
cat("route:", equal_post$route, "\n")
cat("method:", equal_post$method, "\n")
cat("has_body:", equal_post$has_body, "\n")
cat("path_params:", equal_post$path_params, "\n")
cat("query_params:", equal_post$query_params, "\n")
cat("body_params:", equal_post$body_params, "\n")
cat("num_path_params:", equal_post$num_path_params, "\n")
cat("request_type:", equal_post$request_type, "\n")

# Debug: check what the logic would compute
method_lower <- tolower(equal_post$method)
has_body_val <- equal_post$has_body
path_names_count <- equal_post$num_path_params
cat("\nDebug computed request_type:\n")
cat("  method_lower:", method_lower, "\n")
cat("  method_lower %in% c('post', 'put', 'patch'):", method_lower %in% c("post", "put", "patch"), "\n")
cat("  has_body:", has_body_val, "\n")
cat("  condition (method in POST/PUT/PATCH && has_body):", method_lower %in% c("post", "put", "patch") && has_body_val, "\n")

# Now let's trace through the pipeline
cat("\n=== Tracing through ct_endpoint_eval.R pipeline ===\n")

# Simulate the pipeline transformation (matching ct_endpoint_eval.R exactly)
test_spec <- spec %>%
  filter(grepl("search/equal", route)) %>%
  mutate(
    # Clean route: remove {param} placeholders, leading slashes (overwrites route!)
    route = strip_curly_params(route, leading_slash = 'remove'),

    # Extract domain from route (first path segment)
    domain = route %>%
      stringr::str_extract(., "^[^/]+"),

    # Generate file name from route
    name = route %>%
      str_remove_all(
        regex("(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies)|summary|by[/_-]dtxsid)(?=$|[/_-])")
      ) %>%
      str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
      str_replace_all("[/]+", " ") %>%
      str_squish() %>%
      str_replace_all(., pattern = "\\s", replacement = "_") %>%
      str_replace_all(., pattern = "-", replacement = "_"),

    # Build full file name with prefix
    file = case_when(
      nchar(name) == 0 ~ paste0("ct_", domain, ".R"),
      str_detect(name, pattern = domain) ~ paste0("ct_", name, ".R"),
      .default = paste0("ct_", domain, "_", name, ".R")
    ),

    # Set batch_limit
    batch_limit = case_when(
      method == 'GET' & !is.na(num_path_params) & num_path_params > 0 ~ 1,
      method == 'GET' & !is.na(num_path_params) & num_path_params == 0 ~ 0,
      .default = NULL
    )
  )

cat("\nAfter pipeline transformation:\n")
print(test_spec %>% select(route, name, file, method, path_params, query_params, batch_limit, num_path_params, request_type))

# Group and set function names
test_spec <- test_spec %>%
  group_by(file) %>%
  mutate(
    method_count = n(),
    fn = case_when(
      method_count == 1 ~ tools::file_path_sans_ext(basename(file)),
      method == "GET" ~ tools::file_path_sans_ext(basename(file)),
      method == "POST" ~ paste0(tools::file_path_sans_ext(basename(file)), "_bulk"),
      .default = paste0(tools::file_path_sans_ext(basename(file)), "_", tolower(method))
    )
  ) %>%
  ungroup()

cat("\nFinal function names:\n")
print(test_spec %>% select(route, fn, file, method, path_params, query_params, batch_limit, request_type))

# Now render the stubs
cat("\n=== Rendering stubs ===\n")
rendered <- render_endpoint_stubs(test_spec, config = ct_config)

cat("\nGenerated code for GET endpoint:\n")
cat("----------------------------------------\n")
get_row <- rendered %>% filter(method == "GET")
cat(get_row$text, "\n")

cat("\nGenerated code for POST endpoint:\n")
cat("----------------------------------------\n")
post_row <- rendered %>% filter(method == "POST")
cat(post_row$text, "\n")
