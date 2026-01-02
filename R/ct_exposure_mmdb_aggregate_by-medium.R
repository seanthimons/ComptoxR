#' Get Aggregate data by Medium
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param pageNumber Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_aggregate_by_medium(query = "DTXSID7020182")
#' }
ct_exposure_mmdb_aggregate_by_medium <- function(query, pageNumber = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(pageNumber)) extra_params$pageNumber <- pageNumber

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "exposure/mmdb/aggregate/by-medium",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}