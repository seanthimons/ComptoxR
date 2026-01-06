#' Get Single Sample data by DTXSID
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
#' ct_exposure_mmdb_single_sample(dtxsid = "DTXSID7020182")
#' }
ct_exposure_mmdb_single_sample <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "exposure/mmdb/single-sample/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

