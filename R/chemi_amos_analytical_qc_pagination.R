#' Returns information on a batch of Analytical QC documents.  Intended to be used for pagination of the data instead of trying to transfer all the information in one transaction.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_pagination()
#' }
chemi_amos_analytical_qc_pagination <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/analytical_qc_pagination/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


