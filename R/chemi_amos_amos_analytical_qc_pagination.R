#' Returns information on a batch of Analytical QC documents.  Intended to be used for pagination of the data instead of trying to transfer all the information in one transaction.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param offset Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_amos_analytical_qc_pagination(query = "DTXSID7020182")
#' }
chemi_amos_amos_analytical_qc_pagination <- function(query, offset = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(offset)) options$offset <- offset

  generic_chemi_request(
    query = query,
    endpoint = "api/amos/analytical_qc_pagination/",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}