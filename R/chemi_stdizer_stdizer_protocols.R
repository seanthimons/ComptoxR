#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param id Optional parameter
#' @param pageable Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_stdizer_protocols(query = "DTXSID7020182")
#' }
chemi_stdizer_stdizer_protocols <- function(query, id = NULL, pageable = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(id)) options$id <- id
  if (!is.null(pageable)) options$pageable <- pageable

  generic_chemi_request(
    query = query,
    endpoint = "api/stdizer/protocols/",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}