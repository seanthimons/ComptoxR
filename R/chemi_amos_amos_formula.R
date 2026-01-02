#' Returns a list of substances that have the given molecular formula.
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
#' chemi_amos_amos_formula(query = "DTXSID7020182")
#' }
chemi_amos_amos_formula <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/formula_search/",
    server = "chemi_burl",
    auth = FALSE
  )
}

