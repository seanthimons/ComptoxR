#' Get bioactivity data for a batch of DTXSIDs
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
#' ct_bioactivity_data(query = "DTXSID7020182")
#' }
ct_bioactivity_data <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-dtxsid/",
    method = "POST",
		batch_limit = NA
  )
}

#' Get summary data by DTXSID
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
#' ct_bioactivity_data(query = "DTXSID7020182")
#' }
ct_bioactivity_data <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/summary/search/by-dtxsid/",
    method = "GET",
		batch_limit = 1
  )
}

