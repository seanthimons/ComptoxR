#' Retrieves a list of methods in the database with their supplemental information.
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
#' chemi_amos_amos_method_list(query = "DTXSID7020182")
#' }
chemi_amos_amos_method_list <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/method_list",
    server = "chemi_burl",
    auth = FALSE
  )
}

