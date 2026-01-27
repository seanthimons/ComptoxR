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
#' ct_exposure_product_data_search_bulk(query = c("DTXSID301027109", "DTXSID1060138", "DTXSID90893948"))
#' }
ct_exposure_product_data_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "exposure/product-data/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get product data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_product_data_search(dtxsid = "DTXSID0020232")
#' }
ct_exposure_product_data_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "exposure/product-data/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


