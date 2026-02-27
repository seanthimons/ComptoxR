#' Get product data for a batch of DTXSIDs
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
#' ct_exposure_product_data(query = "DTXSID7020182")
#' }
ct_exposure_product_data <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "exposure/product-data/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


