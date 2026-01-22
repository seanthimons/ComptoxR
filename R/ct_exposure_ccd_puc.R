#' Get Product Use Category data by DTXSID
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
#' ct_exposure_ccd_puc(dtxsid = "DTXSID0020232")
#' }
ct_exposure_ccd_puc <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "exposure/ccd/puc/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

