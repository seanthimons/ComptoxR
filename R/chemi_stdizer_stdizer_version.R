#' 
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
#' chemi_stdizer_stdizer_version(query = "DTXSID7020182")
#' }
chemi_stdizer_stdizer_version <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/stdizer/version",
    server = "chemi_burl",
    auth = FALSE
  )
}

