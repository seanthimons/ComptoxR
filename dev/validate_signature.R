# Validate ct_chemical_search_equal_bulk function signature
# Task 2: VAL-01 requirement check

library(cli)

# Load package functions
devtools::load_all()

# Get formal parameters
fn <- ct_chemical_search_equal_bulk
params <- names(formals(fn))

cat("=== FUNCTION SIGNATURE VALIDATION ===\n\n")
cat("Function:", "ct_chemical_search_equal_bulk\n")
cat("Parameters:", paste(params, collapse = ", "), "\n\n")

# VAL-01: Check for query parameter
if (!"query" %in% params) {
  cli::cli_abort("VAL-01 FAILED: ct_chemical_search_equal_bulk missing 'query' parameter")
}

cli::cli_alert_success("VAL-01 PASSED: ct_chemical_search_equal_bulk has 'query' parameter")

# Verify no other unexpected parameters (should only have query)
expected_params <- c("query")
if (!setequal(params, expected_params)) {
  unexpected <- setdiff(params, expected_params)
  missing <- setdiff(expected_params, params)

  if (length(unexpected) > 0) {
    cli::cli_warn("Unexpected parameters: {paste(unexpected, collapse=', ')}")
  }
  if (length(missing) > 0) {
    cli::cli_warn("Missing expected parameters: {paste(missing, collapse=', ')}")
  }
} else {
  cli::cli_alert_success("Parameter list matches expected: {paste(expected_params, collapse=', ')}")
}

cat("\n=== VALIDATION COMPLETE ===\n")
