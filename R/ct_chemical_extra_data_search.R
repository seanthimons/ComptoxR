#' Get data for a batch of DTXSIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_extra_data_search_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_extra_data_search_bulk <- function(query) {
  params <- list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "chemical/extra-data/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_extra_data_search(dtxsid = "DTXSID101296374")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_extra_data_search <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "chemical/extra-data/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
