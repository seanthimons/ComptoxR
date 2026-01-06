#' Get HAWC link by DTXSID
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
#' ct_hazard_hawc(dtxsid = "DTXSID7020182")
#' }
ct_hazard_hawc <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "hazard/hawc/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

