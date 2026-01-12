#' Returns a list of methods and fact sheets, each of which contain at least one substance of sufficient similarity to the searched substance.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_similar_structures(dtxsid = "DTXSID7020182")
#' }
chemi_amos_get_similar_structures <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "amos/get_similar_structures/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


