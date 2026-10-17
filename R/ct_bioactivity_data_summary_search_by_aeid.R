#' Get summary data by AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid ToxCast assay component endpoint ID (AEID). Type: integer
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_summary_search_by_aeid(aeid = "3032")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_summary_search_by_aeid <- function(aeid) {
  params <- base::list("aeid" = aeid)
  result <- generic_request(
    "query" = params[["aeid"]],
    "endpoint" = "bioactivity/data/summary/search/by-aeid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
