#' Retrieves a mass spectrum by its ID in AMOS's database with supporting information.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the mass spectrum of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_mass_spectrum(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_mass_spectrum <- function(internal_id) {
  generic_request(
    query = internal_id,
    endpoint = "amos/get_mass_spectrum/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


