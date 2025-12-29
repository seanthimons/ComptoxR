#' Retrieves data on known or predicted genotoxic effects by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_genotox(query = "DTXSID7020182")
#' }
ct_genotox <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/genetox/details/search/by-dtxsid/",
    method = "POST"
  )
}
