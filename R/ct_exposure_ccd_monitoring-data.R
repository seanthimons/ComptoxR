#' Get Biomonitoring data by DTXSID with CCD projection
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier
#' @param projection Specifies if projection is used. Option: ccd-biomonitoring, If omitted, the default CCDBiomonitoring data is returned.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_ccd_monitoring_data(dtxsid = "DTXSID7020182")
#' }
ct_exposure_ccd_monitoring_data <- function(dtxsid, projection = NULL) {
  generic_request(
    query = dtxsid,
    endpoint = "exposure/ccd/monitoring-data/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    projection = projection
  )
}

