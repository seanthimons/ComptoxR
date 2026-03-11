# Bioactivity Hook Primitives
# Hooks for bioactivity data operations

#' Annotate assay results if requested
#'
#' Post-response hook that joins assay annotation data when annotate=TRUE.
#' Performs a secondary request to ct_bioactivity_assay() and joins by aeid.
#'
#' @param data Hook data structure with list(result = ..., params = list(annotate = ...))
#' @return Original result or result with joined assay annotations
#' @noRd
annotate_assay_if_requested <- function(data) {
  if (!isTRUE(data$params$annotate)) {
    return(data$result)
  }

  # Get all assay annotations
  bioassay_all <- ct_bioactivity_assay()

  # Join with result by aeid
  result <- dplyr::left_join(data$result, bioassay_all, by = "aeid")

  return(result)
}
