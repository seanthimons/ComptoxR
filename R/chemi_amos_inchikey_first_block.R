#' Returns a list of substances found by InChIKey.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param first_block First block of an InChIKey.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_inchikey_first_block(first_block = "DTXSID7020182")
#' }
chemi_amos_inchikey_first_block <- function(first_block) {
  generic_request(
    query = first_block,
    endpoint = "amos/inchikey_first_block_search/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


