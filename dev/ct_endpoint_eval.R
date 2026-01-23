# ==============================================================================
# CompTox Dashboard Endpoint Evaluation and Stub Generation
# ==============================================================================
#
# This script analyzes OpenAPI schemas from the CompTox Chemistry Dashboard API
# and generates R function stubs for endpoints that are not yet implemented.
#
# Workflow:
#   1. Load OpenAPI schemas from schema/ directory
#   2. Parse endpoint specifications
#   3. Search existing codebase for implementations
#   4. Generate function stubs for missing endpoints
#   5. Write stubs to R/ directory (toggle overwrite/append as needed)
#
# Usage:
#   source("endpoint eval.R")
#
# ==============================================================================

# Load shared utilities
source(here::here("dev", "endpoint_eval_utils.R"))

# Load required packages
library(jsonlite)
library(tidyverse)

# ==============================================================================
# Configuration
# ==============================================================================

# CompTox (ct_*) function generation configuration
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# ==============================================================================
# Load and Parse OpenAPI Schemas
# ==============================================================================

# Find all ctx production schema files
ctx_schema_files <- list.files(
  path = here::here('schema'),
  pattern = "^ctx_.*_prod\\.json$",
  full.names = FALSE
)

# Parse all schemas and combine into single endpoint specification
endpoints <- map(
  ctx_schema_files,
  ~ {
    openapi <- jsonlite::fromJSON(here::here('schema', .x), simplifyVector = FALSE)
    dat <- openapi_to_spec(openapi)
  },
  .progress = TRUE
) %>%
  list_rbind() %>%
  mutate(
    # Clean route: remove {param} placeholders, leading slashes
    route = strip_curly_params(route, leading_slash = 'remove'),

    # Extract domain from route (first path segment)
    domain = route %>%
      stringr::str_extract(., "^[^/]+"),

    # Generate file name from route
    # Remove common prefixes/suffixes, collapse to clean identifier
    file = route %>%
      # 1) Remove tokens with optional left separator, only when delimited on the right
      str_remove_all(
        regex("(?i)(?:^|[/_-])(?:hazards?|chemical?|exposures?|bioactivit(?:y|ies)|search(?:es)?|summary|by[/_-]dtxsid)(?=$|[/_-])")
      ) %>%
      str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
      # 2) Collapse any remaining separators to spaces
      str_replace_all("[/]+", " ") %>%
      # 3) Trim and normalize whitespace
      str_squish() %>%
      # 4) Replace spaces with underscores
      str_replace_all(., pattern = "\\s", replacement = "_"),

    # Build full file name with prefix
    file = paste0("ct_", domain, "_", file, ".R"),

    # Set batch_limit:
    # - GET with path params: 1 (single item appended to path)
    # - GET without path params: 0 (static endpoint, params go in query string)
    # - POST: NULL (bulk, uses default batching)
    batch_limit = case_when(
      method == 'GET' & !is.na(num_path_params) & num_path_params > 0 ~ 1,
      method == 'GET' & !is.na(num_path_params) & num_path_params == 0 ~ 0,
      .default = NULL
    )
  ) %>%
  # Sort by domain, route, method (POST before GET)
  arrange(
    forcats::fct_inorder(domain),
    route,
    factor(method, levels = c('POST', 'GET'))
  ) %>%
  # Remove duplicates (prefer first occurrence per route)
  distinct(route, .keep_all = TRUE)

# ==============================================================================
# Find Missing Endpoints
# ==============================================================================

# Search R/ directory for existing endpoint implementations
res <- find_endpoint_usages_base(
	endpoints$route, 
	pkg_dir = here::here("R"),
	files_regex = "^ct_.*\\.R$",
	expected_files = endpoints$file
)

# Filter to endpoints with no hits (not yet implemented)
endpoints_to_build <- endpoints %>%
  filter(route %in% {res$summary %>% filter(n_hits == 0) %>% pull(endpoint)})

# ==============================================================================
# Generate Function Stubs
# ==============================================================================

# Render R function source code using unified template
spec_with_text <- render_endpoint_stubs(
  endpoints_to_build,
  config = ct_config
)

# ==============================================================================
# Write Files to Disk
# ==============================================================================

# NOTE: Toggle overwrite and append parameters as needed
# - overwrite = FALSE: skip existing files (safe mode)
# - overwrite = TRUE: replace existing files (use with caution)
# - append = TRUE: append to existing files (use for adding to existing files)

# ! BUILD ----
# Uncomment to generate files:
scaffold_result <- scaffold_files(spec_with_text, base_dir = "R", overwrite = FALSE, append = TRUE)

# Inspect results (which files were created/skipped/errored):
scaffold_result %>% filter(action == "skipped")  # Files that already existed
scaffold_result %>% filter(action == "error")    # Files that failed to write

# ==============================================================================
# Cleanup
# ==============================================================================

# Remove intermediate variables (keep spec_with_text for inspection)
# rm(
#   ct_config,
#   ctx_schema_files,
#   endpoints,
#   res,
#   endpoints_to_build
# )

# ==============================================================================
# Test loading
# ==============================================================================

devtools::document()
#devtools::load_all()
