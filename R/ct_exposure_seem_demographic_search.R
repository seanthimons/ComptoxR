#' Get SEEM Demographic Exposure Prediction data for batch of DTXSIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_seem_demographic_search_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_seem_demographic_search_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "exposure/seem/demographic/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get SEEM Demographic Exposure Prediction data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies whether to use projection. Optional: ccd-demographic.
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_seem_demographic_search(dtxsid = "DTXSID0020232")
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_seem_demographic_search <- function(dtxsid, projection = NULL) {
  params <- base::list("dtxsid" = dtxsid, "projection" = projection)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "exposure/seem/demographic/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
