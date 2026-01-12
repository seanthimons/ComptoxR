#' Get all product use categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_product_data_puc(query = "DTXSID7020182")
#' }
ct_exposure_product_data_puc <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/product-data/puc",
    method = "GET",
    batch_limit = 1
  )
}

