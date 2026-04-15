#' Calculate Uncertainty Metrics for GenRA Predictions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Computes uncertainty quantification for GenRA read-across predictions using
#' permutation testing and (optionally) ROC-AUC analysis.
#'
#' @param activities Integer vector of activity values (0 = inactive, 1 = active).
#'   NA values are allowed and will be excluded.
#' @param similarities Numeric vector of similarity scores (0-1), must be same
#'   length as `activities`.
#' @param n_permutations Integer. Number of permutations for p-value calculation.
#'   Default is 100.
#'
#' @return A list with components:
#' \describe{
#'   \item{swa}{The observed Similarity-Weighted Activity score.}
#'   \item{auc}{Area Under the ROC Curve (requires pROC package), or NA if
#'     unavailable or insufficient data.
#'   }
#'   \item{p_value}{Permutation-based p-value. Proportion of permuted SWA values
#'     as extreme as observed.
#'   }
#'   \item{threshold}{Suggested classification threshold (default 0.5).}
#'   \item{n_active}{Number of active analogues used.}
#'   \item{n_inactive}{Number of inactive analogues used.}
#'   \item{n_permutations}{Number of permutations performed.}
#' }
#'
#' @details
#' The p-value is calculated via permutation testing: activity labels are
#' shuffled `n_permutations` times while keeping similarity weights fixed.
#' The p-value is the proportion of permuted SWA values >= the observed SWA
#' (for positive predictions) or <= observed SWA (for negative predictions).
#'
#' AUC calculation requires the pROC package and at least one active and one
#' inactive analogue.
#'
#' @seealso [genra_swa()], [genra_predict()]
#'
#' @export
#'
#' @examples
#' \dontrun{
#' activities <- c(1, 1, 0, 1, 0)
#' similarities <- c(0.95, 0.88, 0.82, 0.75, 0.70)
#' genra_uncertainty(activities, similarities, n_permutations = 100)
#' }
genra_uncertainty <- function(activities, similarities, n_permutations = 100L) {
  # Input validation
  if (length(activities) != length(similarities)) {
    cli::cli_abort(
      "Length of {.arg activities} ({length(activities)}) must match
       length of {.arg similarities} ({length(similarities)})."
    )
  }

  n_permutations <- as.integer(n_permutations)
  if (n_permutations < 1) {
    cli::cli_abort("{.arg n_permutations} must be >= 1.")
  }

  # Filter to valid observations
  valid_idx <- !is.na(activities)
  activities <- activities[valid_idx]
  similarities <- similarities[valid_idx]

  n_active <- sum(activities == 1L)
  n_inactive <- sum(activities == 0L)
  n_total <- length(activities)

  # Edge case: no data
  if (n_total == 0) {
    return(list(
      swa = NA_real_,
      auc = NA_real_,
      p_value = NA_real_,
      threshold = 0.5,
      n_active = 0L,
      n_inactive = 0L,
      n_permutations = n_permutations
    ))
  }

  # Calculate observed SWA
  observed_swa <- genra_swa(activities, similarities)

  # Permutation test for p-value
  perm_swa <- vapply(seq_len(n_permutations), function(i) {
    perm_activities <- sample(activities)
    genra_swa(perm_activities, similarities)
  }, FUN.VALUE = numeric(1))

  # Two-tailed p-value: how often is permuted as extreme as observed?
  if (observed_swa >= 0.5) {
    # Positive prediction: count permuted >= observed
    p_value <- mean(perm_swa >= observed_swa)
  } else {
    # Negative prediction: count permuted <= observed
    p_value <- mean(perm_swa <= observed_swa)
  }

  # AUC calculation (requires pROC)
  auc <- NA_real_
  if (n_active >= 1 && n_inactive >= 1) {
    if (requireNamespace("pROC", quietly = TRUE)) {
      tryCatch({
        roc_obj <- pROC::roc(
          response = activities,
          predictor = similarities,
          levels = c(0L, 1L),
          direction = "<",
          quiet = TRUE
        )
        auc <- as.numeric(pROC::auc(roc_obj))
      }, error = function(e) {
        # Keep NA on error
      })
    }
  }

  list(
    swa = observed_swa,
    auc = auc,
    p_value = p_value,
    threshold = 0.5,
    n_active = n_active,
    n_inactive = n_inactive,
    n_permutations = n_permutations
  )
}
