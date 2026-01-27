#' Get SEEM General Exposure Prediction data for a batch of DTXSIDs
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
#' ct_exposure_seem_general_search_bulk(query = c("DTXSID90486733", "DTXSID1025568", "DTXSID90143672"))
#' }
ct_exposure_seem_general_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "exposure/seem/general/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get SEEM General Exposure Prediction data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies whether to use projection. Optional: ccd-general.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_seem_general_search(dtxsid = "DTXSID0020232")
#' }
ct_exposure_seem_general_search <- function(dtxsid, projection = NULL) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "exposure/seem/general/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


