#' Get experimental properties by property and range
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param propertyName Primary query parameter. Type: string
#' @param start Optional parameter. Type: number
#' @param end Optional parameter. Type: number
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_experimental_by_range(propertyName = "DTXSID7020182")
#' }
ct_chemical_property_experimental_by_range <- function(propertyName, start = NULL, end = NULL) {
  result <- generic_request(
    query = propertyName,
    endpoint = "chemical/property/experimental/search/by-range/",
    method = "GET",
    batch_limit = 1,
    path_params = c(start = start, end = end)
  )

  # Additional post-processing can be added here

  return(result)
}


