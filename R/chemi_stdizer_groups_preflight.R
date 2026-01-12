#' Stdizer Groups Preflight
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_preflight(query = "DTXSID7020182")
#' }
chemi_stdizer_groups_preflight <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "stdizer/groups/preflight",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


