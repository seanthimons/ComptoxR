#' Get Production Volume data by DTXSID
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
#' ct_exposure_ccd_production_volume(dtxsid = "DTXSID0020232")
#' }
ct_exposure_ccd_production_volume <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "exposure/ccd/production-volume/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

