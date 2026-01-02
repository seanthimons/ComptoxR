#' Calculates the spectral entropy for a single spectrum.
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
#' chemi_amos_amos_spectral_entropy(query = "DTXSID7020182")
#' }
chemi_amos_amos_spectral_entropy <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/spectral_entropy/",
    server = "chemi_burl",
    auth = FALSE
  )
}

