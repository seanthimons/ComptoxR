#' Get data for a batch of M4IDs
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
#' ct_bioactivity_data_by_m4id(query = "DTXSID7020182")
#' }
ct_bioactivity_data_by_m4id <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-m4id/",
    method = "POST",
		batch_limit = NA
  )
}

