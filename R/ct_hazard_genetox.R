#' Get summary data for a batch of DTXSID
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
#' ct_hazard_genetox(query = "DTXSID7020182")
#' }
ct_hazard_genetox <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/genetox/summary/search/by-dtxsid/",
    method = "POST",
		batch_limit = NA
  )
}

