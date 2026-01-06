#' Get data for a batch of AEIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
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
    batch_limit = NULL
  )
}

