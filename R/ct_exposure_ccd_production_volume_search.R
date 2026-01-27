#' Get Production Volume data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_ccd_production_volume_search(dtxsid = "DTXSID0020232")
#' }
ct_exposure_ccd_production_volume_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "exposure/ccd/production-volume/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


