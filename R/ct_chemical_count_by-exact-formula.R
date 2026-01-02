#' Get chemical count by exact formula
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
#' ct_chemical_count_by_exact_formula(query = "DTXSID7020182")
#' }
ct_chemical_count_by_exact_formula <- function(query, projection = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(projection)) extra_params$projection <- projection

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "chemical/count/by-exact-formula/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}