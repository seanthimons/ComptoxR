#' Returns substance(s) that match a search term.  Since some substance names can have slashes in them, <path> is used
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param search_term A substance identifier.  If it cannot be parsed as an InChIKey, CASRN, or DTXSID, it is assumed to be a name.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_substances_for_term(search_term = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_get_substances_for_term <- function(search_term) {
  params <- list("search_term" = search_term)
  result <- generic_request(
    "query" = params[["search_term"]],
    "endpoint" = "amos/get_substances_for_search_term/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
