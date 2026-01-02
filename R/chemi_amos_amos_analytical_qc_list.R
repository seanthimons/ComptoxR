#' Retrieves information on all the AnalyticalQC PDFs in the database.
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
#' chemi_amos_amos_analytical_qc_list(query = "DTXSID7020182")
#' }
chemi_amos_amos_analytical_qc_list <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/analytical_qc_list/",
    server = "chemi_burl",
    auth = FALSE
  )
}

