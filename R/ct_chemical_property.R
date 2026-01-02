#' Get summary by DTXSID and property
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
#' ct_chemical_property(query = "DTXSID7020182")
#' }
ct_chemical_property <- function(query, propName = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(propName)) extra_params$propName <- propName

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "chemical/property/summary/search/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}#' Get summary by DTXSID
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
#' ct_chemical_property(query = "DTXSID7020182")
#' }
ct_chemical_property <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/property/summary/search/by-dtxsid/",
    method = "GET",
		batch_limit = 1
  )
}

