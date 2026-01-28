#' Search Gethazard
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param sid Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_gethazard(sid = "DTXSID7020182")
#' }
chemi_search_gethazard <- function(sid) {
  # Collect optional parameters
  options <- list()
  if (!is.null(sid)) options[['sid']] <- sid
    result <- generic_request(
    endpoint = "search/gethazard",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


