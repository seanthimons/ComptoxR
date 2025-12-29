#'Retrieves for hazard data by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard(query = "DTXSID7020182")
#' }
ct_hazard <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/toxval/search/by-dtxsid/",
    method = "POST"
  )
}
