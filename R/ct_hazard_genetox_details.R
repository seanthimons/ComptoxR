#' Get detailed data for a batch of DTXSIDs
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
#' ct_hazard_genetox_details_bulk(query = "DTXSID7020182")
#' }
ct_hazard_genetox_details_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/genetox/details/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get detailed data by DTXSID with CCD projection
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies if projection is used. Option: ccd-genetox-details. If no projection is specified, the default GenetoxDetail projection is returned.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_genetox_details(dtxsid = "DTXSID7020182")
#' }
ct_hazard_genetox_details <- function(dtxsid, projection = NULL) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "hazard/genetox/details/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


