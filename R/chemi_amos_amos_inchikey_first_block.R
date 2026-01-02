#' Returns a list of substances found by InChIKey.
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
#' chemi_amos_amos_inchikey_first_block(query = "DTXSID7020182")
#' }
chemi_amos_amos_inchikey_first_block <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/inchikey_first_block_search/",
    server = "chemi_burl",
    auth = FALSE
  )
}

