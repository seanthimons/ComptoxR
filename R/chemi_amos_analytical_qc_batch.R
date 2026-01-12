#' Generates an Excel workbook containing information on all Analytical QC records that contain a given list of DTXSIDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_batch(query = "DTXSID7020182")
#' }
chemi_amos_analytical_qc_batch <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/analytical_qc_batch_search",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


