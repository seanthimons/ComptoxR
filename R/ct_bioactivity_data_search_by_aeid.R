#' Get data for a batch of AEIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_aeid_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_aeid_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/data/search/by-aeid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get data by AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid ToxCast assay component endpoint ID (AEID). Type: integer
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_aeid(aeid = "3032")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_aeid <- function(aeid) {
  params <- base::list("aeid" = aeid)
  result <- generic_request(
    "query" = params[["aeid"]],
    "endpoint" = "bioactivity/data/search/by-aeid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
