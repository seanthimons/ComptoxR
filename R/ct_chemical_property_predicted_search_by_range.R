#' Get predicted properties by property and range
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param propertyId Primary query parameter. Type: string
#' @param start Optional parameter. Type: number
#' @param end Optional parameter. Type: number
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_search_by_range(propertyId = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_property_predicted_search_by_range <- function(propertyId, start = NULL, end = NULL) {
  params <- base::list("propertyId" = propertyId, "start" = start, "end" = end)
  result <- generic_request(
    "query" = params[["propertyId"]],
    "endpoint" = "chemical/property/predicted/search/by-range/",
    "method" = "GET",
    "batch_limit" = 1,
    "path_params" = base::c("start" = params[["start"]], "end" = params[["end"]])
  )
  result
}
