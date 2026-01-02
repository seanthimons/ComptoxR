#' Get predicted properties by property and range
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param start Optional parameter
#' @param end Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_by_range(query = "DTXSID7020182")
#' }
ct_chemical_property_predicted_by_range <- function(query, start = NULL, end = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(start)) extra_params$start <- start
  if (!is.null(end)) extra_params$end <- end

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "chemical/property/predicted/search/by-range/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}