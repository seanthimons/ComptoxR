wrapmaint::bind_tools("drift", environment())
# ==============================================================================
# Parameter Drift Detection
# ==============================================================================
# Purpose: Detect when schema parameters differ from implemented function parameters
# Output: Structured report of drifts (added/removed params) for existing functions
# Usage: Called after finding implemented endpoints to check for parameter changes

# Framework parameters that are added by the stub generator/wrappers
# These should be excluded from drift detection since they're not from the schema
FRAMEWORK_PARAMS <- c(
  "tidy",
  "verbose",
  "...",
  ".verbose",
  ".tidy",
  "all_pages",
  "max_pages"
)

#' Extract function parameters from R source file
#'
#' Attempts parse-based extraction with regex fallback.
#'
#' @param file_path Path to R source file
#' @param function_name Name of function to extract parameters from
#' @return Character vector of parameter names, or NULL if function not found
#' @keywords internal

#' Detect parameter drift between schema and codebase
#'
#' Compares schema parameters with actual function parameters for already-implemented endpoints.
#' Reports additions, removals, and type changes.
#'
#' @param endpoints Tibble from openapi_to_spec() containing schema truth
#' @param usage_summary Summary from find_endpoint_usages_base() with n_hits > 0
#' @param pkg_dir Path to R package directory (default: "R")
#' @return Tibble with columns: endpoint, file, function_name, drift_type, param_name, schema_value, code_value
#' @export
