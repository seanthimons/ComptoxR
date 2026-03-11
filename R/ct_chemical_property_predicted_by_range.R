#' Get predicted properties by property and range
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param propertyId Primary query parameter. Type: string
#' @param start Optional parameter. Type: number
#' @param end Optional parameter. Type: number
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_by_range(propertyId = "DTXSID7020182")
#' }
ct_chemical_property_predicted_by_range <- function(propertyId, start = NULL, end = NULL) {
  result <- generic_request(
    query = propertyId,
    endpoint = "chemical/property/predicted/search/by-range/",
    method = "GET",
    batch_limit = 1,
    path_params = c(start = start, end = end)
  )

  # Additional post-processing can be added here

  return(result)
}


