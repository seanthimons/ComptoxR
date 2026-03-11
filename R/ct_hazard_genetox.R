#' Get summary data for a batch of DTXSID
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
#' ct_hazard_genetox_bulk(query = "DTXSID7020182")
#' }
ct_hazard_genetox_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/genetox/summary/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get summary data by DTXSID
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
#' ct_hazard_genetox(dtxsid = "DTXSID0021125")
#' }
ct_hazard_genetox <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "hazard/genetox/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


