#' Endpoint for retrieving a specified NMR spectrum from the database.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the NMR spectrum of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_nmr_spectrum(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_nmr_spectrum <- function(internal_id) {
  generic_request(
    query = internal_id,
    endpoint = "amos/get_nmr_spectrum/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


