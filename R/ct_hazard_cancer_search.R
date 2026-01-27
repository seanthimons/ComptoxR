#' Get data for a batch of DTXSIDs
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
#' ct_hazard_cancer_search_bulk(query = c("DTXSID60894104", "DTXSID20152651", "DTXSID2021602"))
#' }
ct_hazard_cancer_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "hazard/cancer-summary/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get data by DTXSID
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
#' ct_hazard_cancer_search(dtxsid = "DTXSID0021125")
#' }
ct_hazard_cancer_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "hazard/cancer-summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


