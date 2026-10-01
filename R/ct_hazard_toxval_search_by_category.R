#' Get all data by dtxsid and category
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param category Required parameter
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxval_search_by_category(dtxsid = "DTXSID0021125")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxval_search_by_category <- function(dtxsid, category) {
  params <- base::list("dtxsid" = dtxsid, "category" = category)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "hazard/toxval/search/by-category/",
    "method" = "GET",
    "batch_limit" = 1,
    "category" = params[["category"]]
  )
  result
}
