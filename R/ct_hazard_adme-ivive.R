#' Get ADME data for IVIVE by DTXSID with CCD projection
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param projection Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_adme_ivive(query = "DTXSID7020182")
#' }
ct_hazard_adme_ivive <- function(query, projection = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(projection)) extra_params$projection <- projection

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "hazard/adme-ivive/search/by-dtxsid/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}