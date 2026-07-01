#' Get experimental properties for a batch of DTXSIDs
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
#' ct_chemical_property_experimental_search_bulk(query = "DTXSID1024122")
#' }
ct_chemical_property_experimental_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/property/experimental/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}
