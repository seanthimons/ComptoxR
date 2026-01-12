#' Get Aggregate data by DTXSID
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
#' ct_exposure_mmdb_aggregate(dtxsid = "DTXSID7020182")
#' }
ct_exposure_mmdb_aggregate <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "exposure/mmdb/aggregate/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

