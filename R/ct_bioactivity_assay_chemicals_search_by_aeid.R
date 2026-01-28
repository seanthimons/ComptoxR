#' Get DTXSID list by AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param aeid ToxCast assay component endpoint ID. Type: integer
#' @param projection Optional parameter (default: dtxsidsonly)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_chemicals_search_by_aeid(aeid = "3032")
#' }
ct_bioactivity_assay_chemicals_search_by_aeid <- function(aeid, projection = "dtxsidsonly") {
  result <- generic_request(
    query = aeid,
    endpoint = "bioactivity/assay/chemicals/search/by-aeid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


