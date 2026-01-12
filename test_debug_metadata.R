# Debug test to see metadata flow
library(tidyverse)
library(jsonlite)
source("endpoint_eval_utils.R")

# Load schema
openapi <- jsonlite::fromJSON(here::here('schema', 'ctx_chemical_prod.json'), simplifyVector = FALSE)
endpoints <- openapi_to_spec(openapi)

# Find listName endpoint
list_endpoint <- endpoints %>%
  filter(str_detect(route, "list.*by-name")) %>%
  slice(1)

cat("=== Metadata Structure Debug ===\n\n")
cat("1. Metadata as stored in tibble:\n")
print(list_endpoint$path_param_metadata[[1]])
cat("\n")

cat("2. Accessing listName metadata:\n")
meta <- list_endpoint$path_param_metadata[[1]]$listName
print(str(meta))
cat("   Name:", meta$name, "\n")
cat("   Example:", meta$example, "\n")
cat("   Description:", meta$description, "\n\n")

cat("3. Testing parse_path_parameters directly:\n")
result <- parse_path_parameters(
  path_params_str = "listName",
  strategy = "extra_params",
  metadata = list_endpoint$path_param_metadata[[1]]
)

cat("   Primary param:", result$primary_param, "\n")
cat("   Primary example:", result$primary_example, "\n")
cat("   Param docs:\n")
cat(result$param_docs)
cat("\n")

cat("4. Full parse result:\n")
print(str(result))
