#' Get all toxval supercategories by dtxsid
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
#' ct_hazard_toxval_supercategory(dtxsid = "DTXSID0021125")
#' }
ct_hazard_toxval_supercategory <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "hazard/toxval/supercategory/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

