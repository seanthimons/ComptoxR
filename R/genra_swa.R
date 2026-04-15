#' Calculate Similarity-Weighted Activity (SWA)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Computes the Similarity-Weighted Activity score used in GenRA read-across
#' predictions. The SWA is calculated as the weighted average of analogue
#' activities, where weights are the similarity scores.
#'
#' @param activities Integer vector of activity values (0 = inactive, 1 = active).
#'   NA values are allowed and will be excluded from the calculation.
#' @param similarities Numeric vector of similarity scores (0-1), must be same
#'   length as `activities`.
#'
#' @return Numeric SWA score between 0 and 1, or NA if no valid data.
#'
#' @details
#' The formula is:
#' \deqn{SWA = \frac{\sum_{i} (similarity_i \times activity_i)}{\sum_{i} similarity_i}}
#'
#' Only analogues with non-NA activity values are included in the calculation.
#'
#' @seealso [genra_predict()] for the main prediction workflow.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple example with known activities
#' activities <- c(1, 1, 0, 1, 0)
#' similarities <- c(0.95, 0.88, 0.82, 0.75, 0.70)
#' genra_swa(activities, similarities)
#' }
genra_swa <- function(activities, similarities) {
  # Input validation
 if (length(activities) != length(similarities)) {
    cli::cli_abort(
      "Length of {.arg activities} ({length(activities)}) must match
       length of {.arg similarities} ({length(similarities)})."
    )
  }

  if (!all(similarities >= 0 & similarities <= 1, na.rm = TRUE)) {
    cli::cli_abort("{.arg similarities} must be between 0 and 1.")
  }

  if (!all(activities %in% c(0L, 1L, NA_integer_))) {
    cli::cli_abort("{.arg activities} must be 0, 1, or NA.")
  }

  # Filter to valid (non-NA) observations
 valid_idx <- !is.na(activities)
  activities <- activities[valid_idx]
  similarities <- similarities[valid_idx]

  # Handle edge cases
  if (length(activities) == 0) {
    return(NA_real_)
  }

  sum_weights <- sum(similarities)
  if (sum_weights == 0) {
    return(NA_real_)
  }

  # SWA calculation
  swa <- sum(similarities * activities) / sum_weights

  return(swa)
}
