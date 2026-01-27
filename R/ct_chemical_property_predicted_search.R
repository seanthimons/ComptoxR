#' Get predicted properties for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_search_bulk(query = c("DTXSID8023638", "DTXSID3033511", "DTXSID20582510"))
#' }
ct_chemical_property_predicted_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/property/predicted/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get predicted properties by DTXSID
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
#' ct_chemical_property_predicted_search(dtxsid = "DTXSID7020182")
#' }
ct_chemical_property_predicted_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "chemical/property/predicted/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get predicted property summary by DTXSID and property
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
#' ct_chemical_property_predicted_search(dtxsid = "DTXSID7020182")
#' }
ct_chemical_property_predicted_search <- function(dtxsid, propName) {
  result <- generic_request(
    endpoint = "chemical/property/summary/predicted/search/",
    method = "GET",
    batch_limit = 0,
    `dtxsid` = dtxsid,
    `propName` = propName
  )

  # Additional post-processing can be added here

  return(result)
}


