#' Returns the top four levels of a ClassyFire classification of a given substance.
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
#' chemi_amos_amos_get_classification_for_dtxsid(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_classification_for_dtxsid <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_classification_for_dtxsid/",
    server = "chemi_burl",
    auth = FALSE
  )
}

