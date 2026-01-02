#' Get experimental fate summary by DTXSID and property
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
#' ct_chemical_fate_experimental(query = "DTXSID7020182")
#' }
ct_chemical_fate_experimental <- function(query, propName = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(propName)) extra_params$propName <- propName

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "chemical/fate/summary/experimental/search/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}