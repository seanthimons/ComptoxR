#' GenRA Read-Across Prediction
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Performs a GenRA-style read-across prediction for a target chemical using
#' Similarity-Weighted Activity (SWA) with ToxValDB data.
#'
#' @param target Character. DTXSID of the target chemical to predict.
#' @param k Integer. Maximum number of analogues to consider. Default is 10.
#' @param min_similarity Numeric. Minimum similarity threshold (0-1) for
#'   analogues. Default is 0.5.
#' @param study_filter Optional character string to filter ToxValDB records by
#'   study type (e.g., "acute", "chronic", "developmental"). Default is NULL.
#' @param n_permutations Integer. Number of permutations for uncertainty
#'   estimation. Default is 100.
#'
#' @return An S3 object of class "genra_prediction" containing:
#' \describe{
#'   \item{target}{The target DTXSID.}
#'   \item{prediction}{Numeric SWA score (0-1).}
#'   \item{predicted_class}{Character: "active", "inactive", or "uncertain".}
#'   \item{auc}{Area Under ROC Curve (or NA if unavailable).}
#'   \item{p_value}{Permutation-based p-value.}
#'   \item{threshold}{Classification threshold used (0.5).}
#'   \item{n_analogues}{Number of analogues with activity data.}
#'   \item{n_analogues_found}{Total analogues found before activity filtering.}
#'   \item{analogues}{Tibble of analogue details (dtxsid, similarity, activity, n_records).}
#'   \item{parameters}{List of input parameters.}
#' }
#'
#' @details
#' The workflow:
#' \enumerate{
#'   \item Find structural analogues using ct_similar()
#'   \item Filter to top k analogues meeting min_similarity threshold
#'   \item Retrieve ToxValDB activity data for analogues
#'   \item Calculate Similarity-Weighted Activity (SWA) prediction
#'   \item Estimate uncertainty via permutation testing and AUC
#' }
#'
#' Classification:
#' \itemize{
#'   \item SWA >= 0.5: "active" (predicted toxic)
#'   \item SWA < 0.5: "inactive" (predicted non-toxic)
#'   \item NA or insufficient data: "uncertain"
#' }
#'
#' @seealso [genra_swa()], [genra_uncertainty()], [genra_get_tox_data()], [ct_similar()]
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Basic prediction for Bisphenol A
#' ctx_server(1)
#' pred <- genra_predict("DTXSID7020182")
#' print(pred)
#'
#' # With study type filter
#' pred <- genra_predict("DTXSID7020182", study_filter = "developmental")
#'
#' # More permutations for better p-value estimate
#' pred <- genra_predict("DTXSID7020182", n_permutations = 1000)
#'
#' # View analogue details
#' pred$analogues
#' }
genra_predict <- function(target,
                          k = 10L,
                          min_similarity = 0.5,
                          study_filter = NULL,
                          n_permutations = 100L) {
  # Input validation
  if (length(target) != 1 || !is.character(target)) {
    cli::cli_abort("{.arg target} must be a single DTXSID character string.")
  }

  if (!grepl("^DTXSID", target)) {
    cli::cli_abort("{.arg target} must be a valid DTXSID (starts with 'DTXSID').")
  }

  k <- as.integer(k)
  if (k < 1) {
    cli::cli_abort("{.arg k} must be >= 1.")
  }

  if (min_similarity < 0 || min_similarity > 1) {
    cli::cli_abort("{.arg min_similarity} must be between 0 and 1.")
  }

  # Step 1: Find analogues
  cli::cli_alert_info("Finding analogues for {.val {target}}...")
  analogues_raw <- ct_similar(target, similarity = min_similarity)

  if (is.null(analogues_raw) || nrow(analogues_raw) == 0) {
    cli::cli_warn("No analogues found for {.val {target}} at similarity >= {min_similarity}.")
    return(.build_genra_result(
      target = target,
      prediction = NA_real_,
      predicted_class = "uncertain",
      auc = NA_real_,
      p_value = NA_real_,
      threshold = 0.5,
      n_analogues = 0L,
      n_analogues_found = 0L,
      analogues = tibble::tibble(
        dtxsid = character(),
        similarity = numeric(),
        activity = integer(),
        n_records = integer()
      ),
      parameters = list(
        k = k,
        min_similarity = min_similarity,
        study_filter = study_filter,
        n_permutations = n_permutations
      )
    ))
  }

  # Standardize column names
  if ("relatedSubstanceDTXSID" %in% names(analogues_raw)) {
    analogues_raw <- dplyr::rename(analogues_raw, dtxsid = relatedSubstanceDTXSID)
  }
  if ("structuralSimilarity" %in% names(analogues_raw)) {
    analogues_raw <- dplyr::rename(analogues_raw, similarity = structuralSimilarity)
  }

  # Sort by similarity and take top k
  analogues_df <- analogues_raw |>
    dplyr::arrange(dplyr::desc(.data$similarity)) |>
    dplyr::slice_head(n = k) |>
    dplyr::select("dtxsid", "similarity")

  n_analogues_found <- nrow(analogues_df)
  cli::cli_alert_success("Found {n_analogues_found} analogue{?s}.")

  # Step 2: Get ToxValDB activity data
  cli::cli_alert_info("Retrieving ToxValDB activity data...")
  tox_data <- genra_get_tox_data(analogues_df$dtxsid, study_filter = study_filter)

  # Merge activity into analogues
  analogues_df <- analogues_df |>
    dplyr::left_join(tox_data, by = "dtxsid")

  # Filter to analogues with activity data
  analogues_with_data <- analogues_df |>
    dplyr::filter(!is.na(.data$activity))

  n_analogues <- nrow(analogues_with_data)

  if (n_analogues == 0) {
    cli::cli_warn("No ToxValDB activity data found for analogues.")
    return(.build_genra_result(
      target = target,
      prediction = NA_real_,
      predicted_class = "uncertain",
      auc = NA_real_,
      p_value = NA_real_,
      threshold = 0.5,
      n_analogues = 0L,
      n_analogues_found = n_analogues_found,
      analogues = analogues_df,
      parameters = list(
        k = k,
        min_similarity = min_similarity,
        study_filter = study_filter,
        n_permutations = n_permutations
      )
    ))
  }

  cli::cli_alert_success("Found activity data for {n_analogues} of {n_analogues_found} analogue{?s}.")

  # Step 3: Calculate SWA and uncertainty
  cli::cli_alert_info("Calculating prediction and uncertainty metrics...")
  uncertainty <- genra_uncertainty(
    activities = analogues_with_data$activity,
    similarities = analogues_with_data$similarity,
    n_permutations = n_permutations
  )

  # Classification
  predicted_class <- dplyr::case_when(
    is.na(uncertainty$swa) ~ "uncertain",
    uncertainty$swa >= 0.5 ~ "active",
    TRUE ~ "inactive"
  )

  # Build result
  result <- .build_genra_result(
    target = target,
    prediction = uncertainty$swa,
    predicted_class = predicted_class,
    auc = uncertainty$auc,
    p_value = uncertainty$p_value,
    threshold = uncertainty$threshold,
    n_analogues = n_analogues,
    n_analogues_found = n_analogues_found,
    analogues = analogues_df,
    parameters = list(
      k = k,
      min_similarity = min_similarity,
      study_filter = study_filter,
      n_permutations = n_permutations
    )
  )

  cli::cli_alert_success("Prediction complete: {.val {predicted_class}} (SWA = {round(uncertainty$swa, 3)})")

  return(result)
}


#' Build GenRA Prediction Result Object
#'
#' @keywords internal
#' @noRd
.build_genra_result <- function(target, prediction, predicted_class, auc, p_value,
                                 threshold, n_analogues, n_analogues_found,
                                 analogues, parameters) {
  structure(
    list(
      target = target,
      prediction = prediction,
      predicted_class = predicted_class,
      auc = auc,
      p_value = p_value,
      threshold = threshold,
      n_analogues = n_analogues,
      n_analogues_found = n_analogues_found,
      analogues = analogues,
      parameters = parameters
    ),
    class = "genra_prediction"
  )
}


#' Print Method for GenRA Predictions
#'
#' @param x A genra_prediction object.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisibly returns the input object.
#'
#' @export
print.genra_prediction <- function(x, ...) {
  cli::cli_h1("GenRA Read-Across Prediction")

  cli::cli_text("Target: {.val {x$target}}")
  cli::cli_rule()

  # Prediction
  if (x$predicted_class == "uncertain") {
    cli::cli_alert_warning("Prediction: {.emph uncertain} (insufficient data)")
  } else {
    class_style <- if (x$predicted_class == "active") "bold red" else "bold green"
    cli::cli_alert_success("Prediction: {.strong {x$predicted_class}}")
    cli::cli_text("  SWA Score: {.val {round(x$prediction, 4)}}")
  }

  cli::cli_rule()

  # Uncertainty metrics
  cli::cli_h2("Uncertainty Metrics")
  auc_str <- if (is.na(x$auc)) "NA" else round(x$auc, 3)
  pval_str <- if (is.na(x$p_value)) "NA" else format(x$p_value, digits = 3)

  cli::cli_bullets(c(
    " " = "AUC: {.val {auc_str}}",
    " " = "p-value: {.val {pval_str}}",
    " " = "Threshold: {.val {x$threshold}}"
  ))

  cli::cli_rule()

  # Analogue summary
  cli::cli_h2("Analogues")
  cli::cli_bullets(c(
    " " = "Found: {.val {x$n_analogues_found}}",
    " " = "With activity data: {.val {x$n_analogues}}"
  ))

  if (x$n_analogues > 0) {
    n_active <- sum(x$analogues$activity == 1L, na.rm = TRUE)
    n_inactive <- sum(x$analogues$activity == 0L, na.rm = TRUE)
    cli::cli_bullets(c(
      " " = "Active: {.val {n_active}}",
      " " = "Inactive: {.val {n_inactive}}"
    ))
  }

  cli::cli_rule()

  # Parameters
  cli::cli_h2("Parameters")
  cli::cli_bullets(c(
    " " = "k: {.val {x$parameters$k}}",
    " " = "min_similarity: {.val {x$parameters$min_similarity}}",
    " " = "study_filter: {.val {x$parameters$study_filter %||% 'NULL'}}",
    " " = "n_permutations: {.val {x$parameters$n_permutations}}"
  ))

  invisible(x)
}
