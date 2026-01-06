#' Get PPRTV data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_pprtv(dtxsid = "DTXSID2040282")
#' }
ct_hazard_pprtv <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "hazard/pprtv/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

