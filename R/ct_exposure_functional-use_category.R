#' Get functional use categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_functional_use_category()
#' }
ct_exposure_functional_use_category <- function() {
  result <- generic_request(
    endpoint = "exposure/functional-use/category",
    method = "GET",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


