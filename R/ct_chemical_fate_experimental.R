#' Get experimental fate summary by DTXSID and property
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Optional parameter
#' @param propName Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_fate_experimental(query = "DTXSID7020182")
#' }
ct_chemical_fate_experimental <- function(query, dtxsid = NULL, propName = NULL) {
  generic_request(
    query = query,
    endpoint = "chemical/fate/summary/experimental/search/",
    method = "GET",
    batch_limit = 1,
    dtxsid = dtxsid,
    propName = propName
  )
}

