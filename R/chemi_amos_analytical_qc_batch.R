#' Generates an Excel workbook containing information on all Analytical QC records that contain a given list of DTXSIDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_batch()
#' }
chemi_amos_analytical_qc_batch <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/analytical_qc_batch_search",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


