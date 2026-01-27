#' Get SEEM Demographic Exposure Prediction data for batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_seem_demographic_search_bulk(query = c("DTXSID00176779", "DTXSID20152651", "DTXSID20964832"))
#' }
ct_exposure_seem_demographic_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "exposure/seem/demographic/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get SEEM Demographic Exposure Prediction data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies whether to use projection. Optional: ccd-demographic.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_seem_demographic_search(dtxsid = "DTXSID0020232")
#' }
ct_exposure_seem_demographic_search <- function(dtxsid, projection = NULL) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "exposure/seem/demographic/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


