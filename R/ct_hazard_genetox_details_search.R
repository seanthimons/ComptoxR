#' Get detailed data for a batch of DTXSIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_details_search_bulk(query = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_details_search_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "hazard/genetox/details/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get detailed data by DTXSID with CCD projection
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies if projection is used. Option: ccd-genetox-details. If no projection is specified, the default GenetoxDetail projection is returned.
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_details_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_details_search <- function(dtxsid, projection = NULL) {
  params <- base::list("dtxsid" = dtxsid, "projection" = projection)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "hazard/genetox/details/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
