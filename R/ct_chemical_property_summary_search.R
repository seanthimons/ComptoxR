#' Get summary by DTXSID and property
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Required parameter
#' @param propName Required parameter
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_summary_search(dtxsid = "DTXSID7020182")
#' }
ct_chemical_property_summary_search <- function(dtxsid, propName) {
  result <- generic_request(
    endpoint = "chemical/property/summary/search/",
    method = "GET",
    batch_limit = 0,
    `dtxsid` = dtxsid,
    `propName` = propName
  )

  # Additional post-processing can be added here

  return(result)
}
