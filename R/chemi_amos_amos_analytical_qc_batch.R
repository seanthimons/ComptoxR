#' Generates an Excel workbook containing information on all Analytical QC records that contain a given list of DTXSIDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_amos_analytical_qc_batch(query = "DTXSID7020182")
#' }
chemi_amos_amos_analytical_qc_batch <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/analytical_qc_batch_search",
    server = "chemi_burl",
    auth = FALSE
  )
}

