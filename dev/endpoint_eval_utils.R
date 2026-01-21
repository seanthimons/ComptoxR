# ==============================================================================
# Endpoint Evaluation Utilities
# ==============================================================================
#
# Shared utility functions for OpenAPI schema-driven code generation.
# Used by endpoint eval.R and chemi_endpoint_eval.R to generate R function
# stubs from EPA CompTox API specifications.
#
# This file is now a main entry point that sources modular components from
# the dev/endpoint_eval/ directory.
#
# Usage:
#   source("dev/endpoint_eval_utils.R")
#
# ==============================================================================

# Load required packages
library(jsonlite)
library(tidyverse)

# Get the directory of this script to find modules
# We use this robust method to ensure sourcing works even if called from elsewhere
get_script_path <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- "--file="
  res <- grep(file_arg, cmd_args, value = TRUE)
  if (length(res) > 0) {
    return(normalizePath(sub(file_arg, "", res[1])))
  }
  # Fallback for interactive sessions (like RStudio)
  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(normalizePath(sys.frames()[[1]]$ofile))
  }
  # Default to current directory if script path cannot be determined
  return(getwd())
}

utils_dir <- file.path(dirname(get_script_path()), "endpoint_eval")

# Source modules in dependency order
source(file.path(utils_dir, "00_config.R"))
source(file.path(utils_dir, "01_schema_resolution.R"))
source(file.path(utils_dir, "02_path_utils.R"))
source(file.path(utils_dir, "03_codebase_search.R"))
source(file.path(utils_dir, "04_openapi_parser.R"))
source(file.path(utils_dir, "05_file_scaffold.R"))
source(file.path(utils_dir, "06_param_parsing.R"))
source(file.path(utils_dir, "07_stub_generation.R"))
