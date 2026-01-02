#' Get all data by dtxsid and category
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param category Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxval_by_category(query = "DTXSID7020182")
#' }
ct_hazard_toxval_by_category <- function(query, category = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(category)) extra_params$category <- category

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "hazard/toxval/search/by-category/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}