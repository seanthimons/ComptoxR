#' Get General Use Keywords data by DTXSID
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
#' ct_exposure_ccd_keywords(dtxsid = "DTXSID0020232")
#' }
ct_exposure_ccd_keywords <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "exposure/ccd/keywords/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

