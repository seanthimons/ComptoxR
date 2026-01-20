#' Endpoint for retrieving a specified NMR spectrum from the database.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_nmr_spectrum()
#' }
chemi_amos_get_nmr_spectrum <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_nmr_spectrum/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


