#' Get PPRTV data by DTXSID
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
#' ct_hazard_pprtv_search(dtxsid = "DTXSID2040282")
#' }
ct_hazard_pprtv_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "hazard/pprtv/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


