#' Get all data by dtxsid and category
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier
#' @param category Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxval_by_category(dtxsid = "DTXSID0021125")
#' }
ct_hazard_toxval_by_category <- function(dtxsid, category = NULL) {
  generic_request(
    query = dtxsid,
    endpoint = "hazard/toxval/search/by-category/",
    method = "GET",
    batch_limit = 1,
    category = category
  )
}

