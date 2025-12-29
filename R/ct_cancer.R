#' Retrieves cancer-related hazard and risk values for a give DTXSID
#'
#'Values returned include source and URL, level of known or predicted risk, and exposure route (if known).
#'Cancer slope values and THQ values can also be found from running the `ct_hazard()` or `ct_ghs` functions.
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_cancer(query = "DTXSID7020182")
#' }
ct_cancer <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/cancer-summary/search/by-dtxsid/",
    method = "POST"
  )
}
