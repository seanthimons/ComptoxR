#' Calculates the entropy similarity for two spectra.
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
#' chemi_amos_amos_entropy_similarity(query = "DTXSID7020182")
#' }
chemi_amos_amos_entropy_similarity <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/entropy_similarity/",
    server = "chemi_burl",
    auth = FALSE
  )
}

