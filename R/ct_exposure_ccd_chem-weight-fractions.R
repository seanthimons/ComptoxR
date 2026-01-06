#' Get Chemical Weight Fractions data by DTXSID
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
#' ct_exposure_ccd_chem_weight_fractions(dtxsid = "DTXSID0020232")
#' }
ct_exposure_ccd_chem_weight_fractions <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "exposure/ccd/chem-weight-fractions/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

