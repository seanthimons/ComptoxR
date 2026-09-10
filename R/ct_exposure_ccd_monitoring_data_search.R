#' Get Biomonitoring data by DTXSID with CCD projection
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies if projection is used. Option: ccd-biomonitoring, If omitted, the default CCDBiomonitoring data is returned.
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_ccd_monitoring_data_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_ccd_monitoring_data_search <- function(dtxsid, projection = NULL) {
  params <- list("dtxsid" = dtxsid, "projection" = projection)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "exposure/ccd/monitoring-data/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
