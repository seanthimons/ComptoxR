#' Get AED data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_aed_search_bulk(query = c("DTXSID601026093", "DTXSID30203567", "DTXSID7022883"))
#' }
ct_bioactivity_data_aed_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/data/aed/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get AED data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Primary query parameter. Type: string
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_aed_search(dtxsid = "DTXSID5021209")
#' }
ct_bioactivity_data_aed_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "bioactivity/data/aed/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


