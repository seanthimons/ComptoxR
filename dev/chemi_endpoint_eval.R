# ==============================================================================
# Cheminformatics API Endpoint Evaluation and Stub Generation
# ==============================================================================
#
# This script analyzes OpenAPI schemas from the Cheminformatics microservices API
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
#   source("chemi_endpoint_eval.R")
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

# Cheminformatics (chemi_*) function generation configuration
chemi_config <- list(
  wrapper_function = "generic_chemi_request",
  param_strategy = "options",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# ==============================================================================
# Load and Parse OpenAPI Schemas
# ==============================================================================

# Parse all chemi schemas into a unified super schema using the utility function
# This automatically selects the best available version for each endpoint domain
# (prioritizing prod > staging > dev) and merges them into a single tibble
chemi_endpoints <- parse_chemi_schemas() %>%
  # Filter out PATCH, DELETE methods and render endpoints
  filter(
		str_detect(method, 'GET|POST'),
		!str_detect(route, 'render|replace|add|freeze|metadata|version|reports|download|export|protocols')) %>% 
  mutate(
    # Clean route: remove {param} placeholders, leading slashes
    route = strip_curly_params(route, leading_slash = 'remove'),

    # Extract domain from route (after api/ prefix)
    domain = route %>%
      stringr::str_extract(., "^api/([^/]+)") %>%
      stringr::str_remove("^api/"),

    # Generate file name from route
    # Remove common prefixes/suffixes, collapse to clean identifier
    name = route %>%
      # Remove /api/ prefix and common tokens
      str_remove_all(string = ., pattern = "^api/") %>%
      str_remove_all(
        regex("(?i)(?:^|[/_-])(?:chemi|search(?:es)?|summary|by[/_-]dtxsid)(?=$|[/_-])")
      ) %>%
      str_remove_all(regex("(?i)-summary(?=$|[/_-]|$)")) %>%
      # Collapse any remaining separators to spaces
      str_replace_all("[/]+", " ") %>%
      # Trim and normalize whitespace
      str_squish() %>%
      # Replace spaces with underscores
      str_replace_all(., pattern = "\\s", replacement = "_") %>% 
      # Replace hyphens with underscores
      str_replace_all(., pattern = "-", replacement = "_"),

		#Build full file name with prefix
		file = case_when(
			nchar(name) == 0 ~ paste0("chemi_", domain, ".R"),
			str_detect(name, pattern = domain) ~ paste0("chemi_", name, ".R"),
			.default = paste0("chemi_", domain, "_", name, ".R")
		),

    # Set batch_limit: NULL for chemi endpoints (no batching for cheminformatics API)
    batch_limit = NA_integer_,
		# Seems to be needed to be at the end for this mutate to work properly
		route = str_remove_all(string = route, pattern = "^api/")
  ) %>%
  # Sort by domain, route, method
  # arrange(
  #   forcats::fct_inorder(domain),
  #   route,
  #   #factor(method, levels = c('POST', 'GET'))
	# 	factor(method, levels = c('GET', 'POST'))
  # ) %>%
  # # Remove duplicates (prefer first occurrence per route)
  # distinct(route, .keep_all = TRUE) %>% 
  # Detect GET/POST collisions on same route and generate unique function names
	group_by(file) %>%
	mutate(
		method_count = n(),
		# Generate function name: append _post for POST when collision exists
		fn = case_when(
			method_count == 1 ~ tools::file_path_sans_ext(basename(file)),
			method == "GET" ~ tools::file_path_sans_ext(basename(file)),
			method == "POST" ~ paste0(tools::file_path_sans_ext(basename(file)), "_bulk"),
			.default = paste0(tools::file_path_sans_ext(basename(file)), "_", tolower(method))
		)
	) %>%
	ungroup() %>%
	select(-method_count)

# ==============================================================================
# Find Missing Endpoints
# ==============================================================================

# Search R/ directory for existing endpoint implementations
res_chemi <- find_endpoint_usages_base(
	chemi_endpoints$route, 
	pkg_dir = here::here("R"), 
	files_regex = "^chemi_.*\\.R$",
)

# Filter to endpoints with no hits (not yet implemented)
chemi_endpoints_to_build <- chemi_endpoints %>%
  filter(route %in% {res_chemi$summary %>% filter(n_hits == 0) %>% pull(endpoint)})

# ==============================================================================
# Generate Function Stubs
# ==============================================================================

# Render R function source code using unified template
chemi_spec_with_text <- render_endpoint_stubs(
  chemi_endpoints_to_build,
  config = chemi_config
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
chemi_spec_aggregated <- chemi_spec_with_text %>%
  group_by(file) %>%
  summarise(text = paste(text, collapse = "\n\n"), .groups = "drop")

scaffold_result <- scaffold_files(chemi_spec_aggregated, base_dir = "R", overwrite = TRUE, append = FALSE)

# Inspect results (which files were created/skipped/errored):
scaffold_result %>% filter(str_detect(action, pattern = "skipped"))  # Files that already existed
scaffold_result %>% filter(action == "error")    # Files that failed to write

# ==============================================================================
# Cleanup
# ==============================================================================

# Remove intermediate variables (keep chemi_spec_with_text for inspection)
# rm(
# 	chemi_config, 
# 	chemi_schema_files, 
# 	#chemi_endpoints, 
# 	res_chemi
# 	#chemi_endpoints_to_build
# )

# ==============================================================================
# Test loading
# ==============================================================================

devtools::document()
#devtools::load_all()
