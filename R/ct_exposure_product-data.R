#' Get product data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_product_data(query = "DTXSID7020182")
#' }
ct_exposure_product_data <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/product-data/search/by-dtxsid/",
    method = "POST",
		batch_limit = NA
  )
}

