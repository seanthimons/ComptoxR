#' Get PPRTV data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_pprtv_search(dtxsid = "DTXSID2040282")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_pprtv_search <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "hazard/pprtv/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
