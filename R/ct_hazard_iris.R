#' Get IRIS data by DTXSID
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
#' ct_hazard_iris(query = "DTXSID7020182")
#' }
ct_hazard_iris <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/iris/search/by-dtxsid/",
    method = "GET",
		batch_limit = 1
  )
}

