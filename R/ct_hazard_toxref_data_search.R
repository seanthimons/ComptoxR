#' Get all data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_data_search(dtxsid = "DTXSID1037806")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_data_search <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "hazard/toxref/data/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
