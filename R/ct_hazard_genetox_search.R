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
#' ct_hazard_genetox_search_bulk(query = c("DTXSID80143348", "DTXSID80161401", "DTXSID50474898"))
#' }
ct_hazard_genetox_search_bulk <- function(query) {
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
#' ct_hazard_genetox_search(dtxsid = "DTXSID0021125")
#' }
ct_hazard_genetox_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "hazard/genetox/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


