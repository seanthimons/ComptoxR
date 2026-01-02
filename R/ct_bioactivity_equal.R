#' Search by exact value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_equal(query = "DTXSID7020182")
#' }
ct_bioactivity_equal <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/search/equal/",
    method = "GET",
		batch_limit = 1
  )
}

