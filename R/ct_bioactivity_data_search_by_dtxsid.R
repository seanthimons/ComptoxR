#' Get data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies if projection is used. Option: toxcast-summary-plot. If omitted, the default BioactivityDataAll data is returned.
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_dtxsid(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_dtxsid <- function(dtxsid, projection = NULL) {
  params <- base::list("dtxsid" = dtxsid, "projection" = projection)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "bioactivity/data/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
