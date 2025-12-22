#' Retrieves Chemical Fate and Transport parameters
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_env_fate(query = "DTXSID7020182")
#' }
ct_env_fate <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/fate/search/by-dtxsid/",
    method = "POST"
  )
}
