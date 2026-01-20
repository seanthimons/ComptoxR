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
  result <- generic_request(
    query = NULL,
    endpoint = "amos/analytical_qc_list/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


