#' Get data for a batch of SPIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_spid_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/data/search/by-spid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get data by SPID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param spid sample ID (SPID). Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid(spid = "EPAPLT0232A03")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_spid <- function(spid) {
  params <- base::list("spid" = spid)
  result <- generic_request(
    "query" = params[["spid"]],
    "endpoint" = "bioactivity/data/search/by-spid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
