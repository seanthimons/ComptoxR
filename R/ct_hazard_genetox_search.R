#' Get summary data for a batch of DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_search_bulk(query = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_search_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "hazard/genetox/summary/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get summary data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_search(dtxsid = "DTXSID0021125")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_search <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "hazard/genetox/summary/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
