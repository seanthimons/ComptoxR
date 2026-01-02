#' Get all data by Study Type
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
#' ct_hazard_toxref_data_by_study_type(query = "DTXSID7020182")
#' }
ct_hazard_toxref_data_by_study_type <- function(query, pageNumber = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(pageNumber)) extra_params$pageNumber <- pageNumber

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "hazard/toxref/data/search/by-study-type/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}