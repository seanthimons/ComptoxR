#' Get SEEM General Exposure Prediction data for a batch of DTXSIDs
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
#' ct_exposure_seem_general_search_bulk(query = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
ct_exposure_seem_general_search_bulk <- function(query) {
  params <- list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "exposure/seem/general/search/by-dtxsid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get SEEM General Exposure Prediction data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies whether to use projection. Optional: ccd-general.
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_seem_general_search(dtxsid = "DTXSID0020232")
#' }
# Generated with apipak; do not edit by hand.
ct_exposure_seem_general_search <- function(dtxsid, projection = NULL) {
  params <- list("dtxsid" = dtxsid, "projection" = projection)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "exposure/seem/general/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
