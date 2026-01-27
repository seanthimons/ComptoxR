#' Get all product use categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_product_data_puc()
#' }
ct_exposure_product_data_puc <- function() {
  result <- generic_request(
    endpoint = "exposure/product-data/puc",
    method = "GET",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


