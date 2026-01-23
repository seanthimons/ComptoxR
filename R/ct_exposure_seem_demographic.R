#' Get SEEM Demographic Exposure Prediction data for batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_seem_demographic()
#' }
ct_exposure_seem_demographic <- function() {
  result <- generic_request(
    endpoint = "exposure/seem/demographic/search/by-dtxsid/",
    method = "POST",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


