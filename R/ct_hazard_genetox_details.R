#' Get detailed data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_genetox_details()
#' }
ct_hazard_genetox_details <- function() {
  result <- generic_request(
    endpoint = "hazard/genetox/details/search/by-dtxsid/",
    method = "POST",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


