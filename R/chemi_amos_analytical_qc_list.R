#' Retrieves information on all the AnalyticalQC PDFs in the database.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_list()
#' }
chemi_amos_analytical_qc_list <- function() {
  generic_request(
    query = NULL,
    endpoint = "amos/analytical_qc_list/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


