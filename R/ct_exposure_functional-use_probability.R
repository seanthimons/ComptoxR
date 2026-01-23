#' Get functional use probability by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_functional_use_probability()
#' }
ct_exposure_functional_use_probability <- function() {
  result <- generic_request(
    endpoint = "exposure/functional-use/probability/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


