# Debug script to check body schema extraction
library(here)
library(jsonlite)
library(tidyverse)

# Source utilities
source(here::here("dev", "endpoint_eval_utils.R"))

# Load chemical schema
openapi <- jsonlite::fromJSON(
  here::here("schema", "ctx_chemical_prod.json"),
  simplifyVector = FALSE
)

# Parse endpoints
endpoints <- openapi_to_spec(openapi)

cat("=== ALL ENDPOINTS WITH /chemical/search/equal ===\n")
equal_endpoints <- endpoints %>%
  filter(grepl("chemical/search/equal", route))
print(equal_endpoints[, c("route", "method", "has_body")])

# Find the target endpoint
target <- endpoints %>%
  filter(grepl("chemical/search/equal", route), method == "POST")

cat("\n=== TARGET ENDPOINT COUNT ===\n")
print(nrow(target))

if (nrow(target) == 0) {
  cat("\n✗ No POST endpoint found for /chemical/search/equal\n")
  cat("\nTrying different route patterns...\n")

  # Try without leading slash
  target <- endpoints %>%
    filter(grepl("chemical/search/equal", route), method == "POST")

  print(target[, c("route", "method")])
} else {
  cat("\n=== TARGET ENDPOINT ===\n")
  print(target[, c("route", "method", "has_body", "body_schema_type")])

  cat("\n=== BODY SCHEMA FULL ===\n")
  body_schema <- target$body_schema_full[[1]]
  print(str(body_schema))

  cat("\n=== EXTRACTING BODY PROPERTIES ===\n")
  body_props <- extract_body_properties(body_schema)
  print(body_props)

  cat("\n=== CHECKING SIMPLE BODY TYPE ===\n")
  if (is.data.frame(body_props) && nrow(body_props) > 0) {
    if (body_props$type[1] == "string_array") {
      cat("✓ Detected as string_array (should generate query parameter)\n")
    } else {
      cat("✗ Not detected as string_array, type is:", body_props$type[1], "\n")
    }
  } else {
    cat("✗ No body properties extracted!\n")
  }
}
