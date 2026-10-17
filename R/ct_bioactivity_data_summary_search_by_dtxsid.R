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
#' ct_bioactivity_data_summary_search_by_dtxsid(dtxsid = "DTXSID9026974")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_summary_search_by_dtxsid <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "bioactivity/data/summary/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
