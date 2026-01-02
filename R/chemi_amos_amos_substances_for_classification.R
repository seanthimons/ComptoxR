#' Returns a list of substances in the database which match the specified top four levels of a ClassyFire classification.
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
#' chemi_amos_amos_substances_for_classification(query = "DTXSID7020182")
#' }
chemi_amos_amos_substances_for_classification <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/substances_for_classification/",
    server = "chemi_burl",
    auth = FALSE
  )
}

