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
#' ct_chemical_property(dtxsid = "DTXSID7020182")
#' }
ct_chemical_property <- function(dtxsid, propName) {
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


#' Get summary by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property(dtxsid = "DTXSID7020182")
#' }
ct_chemical_property <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "chemical/property/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


