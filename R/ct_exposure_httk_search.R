#' Get httk data for a batch of DTXSIDs
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
#' ct_exposure_httk_search_bulk(query = c("DTXSID80218080", "DTXSID90893948", "DTXSID1023786"))
#' }
ct_exposure_httk_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "exposure/httk/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get httk data by DTXSID
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
#' ct_exposure_httk_search(dtxsid = "DTXSID0020232")
#' }
ct_exposure_httk_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "exposure/httk/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


