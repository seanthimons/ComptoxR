#' Get analytical QC data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Primary query parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_analyticalqc(dtxsid = "DTXSID7020182")
#' }
ct_bioactivity_analyticalqc <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "bioactivity/analyticalqc/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

