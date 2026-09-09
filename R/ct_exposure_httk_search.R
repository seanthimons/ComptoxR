#' Get httk data for a batch of DTXSIDs
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
#' ct_exposure_httk_search_bulk(query = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
ct_exposure_httk_search_bulk <- function(query) {
  params <- list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "exposure/httk/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get httk data by DTXSID
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
#' ct_exposure_httk_search(dtxsid = "DTXSID0020232")
#' }
# Generated with apipak; do not edit by hand.
ct_exposure_httk_search <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "exposure/httk/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
