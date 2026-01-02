#' Returns a list of methods and fact sheets, each of which contain at least one substance of sufficient similarity to the searched substance.
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
#' chemi_amos_amos_get_similar_structures(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_similar_structures <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_similar_structures/",
    server = "chemi_burl",
    auth = FALSE
  )
}

