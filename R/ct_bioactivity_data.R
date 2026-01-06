#' Get bioactivity data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
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
    batch_limit = NULL
  )
}

