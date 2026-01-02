#' Get data for a batch of DTXCIDs
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
#' ct_chemical_detail_by_dtxcid(query = "DTXSID7020182")
#' }
ct_chemical_detail_by_dtxcid <- function(query, projection = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(projection)) extra_params$projection <- projection

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "chemical/detail/search/by-dtxcid/",
        method = "POST",
		batch_limit = NA
      ),
      extra_params
    )
  )
}