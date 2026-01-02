#' Get data for a batch of AEIDs
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
#' ct_bioactivity_data_by_aeid(query = "DTXSID7020182")
#' }
ct_bioactivity_data_by_aeid <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-aeid/",
    method = "POST",
		batch_limit = NA
  )
}

#' Get summary data by AEID
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
#' ct_bioactivity_data_by_aeid(query = "DTXSID7020182")
#' }
ct_bioactivity_data_by_aeid <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/summary/search/by-aeid/",
    method = "GET",
		batch_limit = 1
  )
}

