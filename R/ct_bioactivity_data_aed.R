#' Get AED data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_aed(query = "DTXSID7020182")
#' }
ct_bioactivity_data_aed <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/aed/search/by-dtxsid/",
    method = "POST",
    batch_limit = NULL
  )
}

