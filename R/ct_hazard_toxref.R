#' Get summary data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid dtxsid
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref(dtxsid = "DTXSID1037806")
#' }
ct_hazard_toxref <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "hazard/toxref/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

