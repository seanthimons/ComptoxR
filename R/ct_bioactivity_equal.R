#' Search by exact value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param value Exact match of search value
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_equal(value = "DTXSID7020182")
#' }
ct_bioactivity_equal <- function(value) {
  generic_request(
    query = value,
    endpoint = "bioactivity/search/equal/",
    method = "GET",
    batch_limit = 1
  )
}

