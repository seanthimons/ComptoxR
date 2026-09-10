#' Get all product use categories
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_product_data_puc()
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_product_data_puc <- function() {
  params <- list()
  result <- generic_request("endpoint" = "exposure/product-data/puc", "method" = "GET", "batch_limit" = 0)
  result
}
