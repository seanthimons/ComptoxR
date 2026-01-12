#' Stdizer Groups Recursive
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Primary query parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_recursive(id = "DTXSID7020182")
#' }
chemi_stdizer_groups_recursive <- function(id) {
  generic_request(
    query = id,
    endpoint = "stdizer/groups/recursive",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


