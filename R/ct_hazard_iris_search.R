#' Get IRIS data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_iris_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_iris_search <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "hazard/iris/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
