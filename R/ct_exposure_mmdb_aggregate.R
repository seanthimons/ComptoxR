#' Get Aggregate data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_aggregate(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_mmdb_aggregate <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "exposure/mmdb/aggregate/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
