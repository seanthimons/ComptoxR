#' Search by starting value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param top Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_start_with(query = "DTXSID7020182")
#' }
ct_bioactivity_start_with <- function(query, top = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(top)) extra_params$top <- top

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "bioactivity/search/start-with/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}