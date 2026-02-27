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
#' ct_bioactivity_data_by_m4id(query = "DTXSID7020182")
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


