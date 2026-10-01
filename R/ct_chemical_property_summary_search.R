#' Get summary by DTXSID and property
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid Required parameter
#' @param propName Required parameter
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_property_summary_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_property_summary_search <- function(dtxsid, propName) {
  params <- base::list("dtxsid" = dtxsid, "propName" = propName)
  result <- generic_request(
    "endpoint" = "chemical/property/summary/search/",
    "method" = "GET",
    "batch_limit" = 0,
    "dtxsid" = params[["dtxsid"]],
    "propName" = params[["propName"]]
  )
  result
}
