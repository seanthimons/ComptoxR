#' Get summary by DTXSID and property
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Required parameter
#' @param propName Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property(dtxsid = "DTXSID7020182")
#' }
ct_chemical_property <- function(dtxsid, propName = NULL) {
  generic_request(
    query = NULL,
    endpoint = "chemical/property/summary/search/",
    method = "GET",
    batch_limit = 0,
    dtxsid = dtxsid,
    propName = propName
  )
}

