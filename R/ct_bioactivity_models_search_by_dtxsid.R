#' Get predictions by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_models_search_by_dtxsid(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_models_search_by_dtxsid <- function(dtxsid) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "bioactivity/models/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
