#' Get data for a batch of M4IDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_by_m4id(query = c("DTXSID3033511", "DTXSID20582510", "DTXSID901336502"))
#' }
ct_bioactivity_data_by_m4id <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-m4id/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


