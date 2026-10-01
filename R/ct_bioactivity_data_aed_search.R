#' Get AED data for a batch of DTXSIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_aed_search_bulk(query = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_aed_search_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/data/aed/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get AED data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid Primary query parameter. Type: string
#' @return Returns a list with result object
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_aed_search(dtxsid = "DTXSID5021209")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_aed_search <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "bioactivity/data/aed/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
