#' Get DTXSIDs for list and containing starting string in chemical name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param word Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_start_with(query = "DTXSID7020182")
#' }
ct_chemical_list_chemicals_start_with <- function(query, word = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(word)) extra_params$word <- word

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "chemical/list/chemicals/search/start-with/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}