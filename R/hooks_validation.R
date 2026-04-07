# Validation Hook Primitives
# Pre-request validation hooks for input data

#' Validate similarity parameter
#'
#' Pre-request hook that validates the similarity parameter is numeric and
#' within valid range (0-1).
#'
#' @param data Hook data structure with list(params = list(similarity = ...))
#' @return Modified data unchanged if valid, aborts with error if invalid
#' @noRd
validate_similarity <- function(data) {
  similarity <- data$params$similarity

  # Check if numeric
  if (!is.numeric(similarity)) {
    cli::cli_abort(c(
      "Invalid similarity parameter",
      "x" = "similarity must be numeric, got {class(similarity)[1]}"
    ))
  }

  # Check range
  if (similarity < 0 || similarity > 1) {
    cli::cli_abort(c(
      "Invalid similarity range",
      "x" = "similarity must be between 0 and 1, got {similarity}"
    ))
  }

  # Return data unchanged if valid
  return(data)
}
