#' Get MS-ready chemicals for a batch of DTXCIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_dtxcid_bulk(query = c("DTXSID5044946", "DTXSID10895040", "DTXSID901027719"))
#' }
ct_chemical_msready_search_by_dtxcid_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/msready/search/by-dtxcid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get MS-ready chemicals by DTXCID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_dtxcid(dtxcid = "DTXCID30182")
#' }
ct_chemical_msready_search_by_dtxcid <- function(dtxcid) {
  result <- generic_request(
    query = dtxcid,
    endpoint = "chemical/msready/search/by-dtxcid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


