#' Get predicted properties for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted(query = "DTXSID7020182")
#' }
ct_chemical_property_predicted <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/property/predicted/search/by-dtxsid/",
    method = "POST",
    batch_limit = NULL
  )
}

