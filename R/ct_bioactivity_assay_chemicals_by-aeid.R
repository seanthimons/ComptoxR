#' Get DTXSID list by AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param aeid ToxCast assay component endpoint ID
#' @param projection Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_chemicals_by_aeid(aeid = "3032")
#' }
ct_bioactivity_assay_chemicals_by_aeid <- function(aeid, projection = NULL) {
  generic_request(
    query = aeid,
    endpoint = "bioactivity/assay/chemicals/search/by-aeid/",
    method = "GET",
    batch_limit = 1,
    projection = projection
  )
}

