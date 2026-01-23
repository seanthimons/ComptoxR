#' Get functional-use data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_functional_use()
#' }
ct_exposure_functional_use <- function() {
  result <- generic_request(
    endpoint = "exposure/functional-use/search/by-dtxsid/",
    method = "POST",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


