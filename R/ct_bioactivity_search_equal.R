#' Search by exact value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param value Exact match of search value. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_search_equal(value = "DTXSID7020182")
#' }
ct_bioactivity_search_equal <- function(value) {
  result <- generic_request(
    query = value,
    endpoint = "bioactivity/search/equal/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


