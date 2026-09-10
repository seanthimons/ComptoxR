#' Get MS-ready chemicals for a batch of DTXCIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_dtxcid_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_dtxcid_bulk <- function(query) {
  params <- list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "chemical/msready/search/by-dtxcid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get MS-ready chemicals by DTXCID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_dtxcid(dtxcid = "DTXCID30182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_dtxcid <- function(dtxcid) {
  params <- list("dtxcid" = dtxcid)
  result <- generic_request(
    "query" = params[["dtxcid"]],
    "endpoint" = "chemical/msready/search/by-dtxcid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
