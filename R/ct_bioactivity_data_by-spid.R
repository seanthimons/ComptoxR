#' Get data for a batch of SPIDs
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
#' ct_bioactivity_data_by_spid(query = c("DTXSID10900961", "DTXSID80726751", "DTXSID2042353"))
#' }
ct_bioactivity_data_by_spid <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-spid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


