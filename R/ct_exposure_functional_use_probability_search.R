#' Get functional use probability by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_functional_use_probability_search(dtxsid = "DTXSID0020232")
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_functional_use_probability_search <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "exposure/functional-use/probability/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
