#' Get observations by DTXSID
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
#' ct_hazard_toxref_observations(dtxsid = "DTXSID1037806")
#' }
ct_hazard_toxref_observations <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "hazard/toxref/observations/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

