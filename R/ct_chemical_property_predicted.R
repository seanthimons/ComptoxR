#' Get predicted properties for a batch of DTXSIDs
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
#' ct_chemical_property_predicted(query = "DTXSID7020182")
#' }
ct_chemical_property_predicted <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/property/predicted/search/by-dtxsid/",
    method = "POST",
		batch_limit = NA
  )
}

#' Get predicted property summary by DTXSID and property
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param propName Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted(query = "DTXSID7020182")
#' }
ct_chemical_property_predicted <- function(query, propName = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(propName)) extra_params$propName <- propName

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "chemical/property/summary/predicted/search/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}