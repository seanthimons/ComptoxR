# Regenerate ct_chemical_search_equal_bulk() stub
# This script uses Phase 1 fixes to generate correct function signature

library(here)
library(jsonlite)
library(tidyverse)

# Source utilities
source(here::here("dev", "endpoint_eval_utils.R"))

# Configuration
ct_config <- list(
  wrapper_function = "generic_request",
  param_strategy = "extra_params",
  example_query = "DTXSID7020182",
  lifecycle_badge = "experimental"
)

# Load chemical schema
openapi <- jsonlite::fromJSON(
  here::here("schema", "ctx_chemical_prod.json"),
  simplifyVector = FALSE
)

# Parse and filter to target endpoint
endpoints <- openapi_to_spec(openapi)
target <- endpoints %>%
  filter(grepl("chemical/search/equal", route), method == "POST")

# Apply transformations
target <- target %>%
  mutate(
    route = strip_curly_params(route, leading_slash = 'remove'),
    file = "ct_chemical_search_equal.R",
    fn = "ct_chemical_search_equal_bulk",
    batch_limit = NULL  # POST endpoint
  )

# Render stub
spec_with_text <- render_endpoint_stubs(target, config = ct_config)

# Output generated code
cat("=== GENERATED FUNCTION STUB ===\n\n")
cat(spec_with_text$text)
cat("\n\n=== END ===\n")

# Write to temporary file for inspection
temp_file <- here::here("dev", "temp_generated_stub.R")
writeLines(spec_with_text$text, temp_file)
cat("\nGenerated stub written to:", temp_file, "\n")
