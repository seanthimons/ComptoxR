#' Get predicted properties by property and range
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param propertyId Primary query parameter
#' @param start Optional parameter
#' @param end Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_by_range(propertyId = "DTXSID7020182")
#' }
ct_chemical_property_predicted_by_range <- function(propertyId, start = NULL, end = NULL) {
  generic_request(
    query = propertyId,
    endpoint = "chemical/property/predicted/search/by-range/",
    method = "GET",
    batch_limit = 1,
    path_params = c(start = start, end = end)
  )
}

