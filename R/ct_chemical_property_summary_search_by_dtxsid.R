#' Get summary by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_property_summary_search_by_dtxsid(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_property_summary_search_by_dtxsid <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "chemical/property/summary/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
