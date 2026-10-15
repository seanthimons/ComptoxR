#' Get analytical QC data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid Primary query parameter. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_analyticalqc_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_analyticalqc_search <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "bioactivity/analyticalqc/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
