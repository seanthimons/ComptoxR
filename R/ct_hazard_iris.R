#' Get IRIS data by DTXSID
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
#' ct_hazard_iris(dtxsid = "DTXSID7020182")
#' }
ct_hazard_iris <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "hazard/iris/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

