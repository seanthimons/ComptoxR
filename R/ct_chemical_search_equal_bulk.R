#' Get chemicals for a batch of exact values
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param query Character vector of values to search for
#' @return A tibble with search results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_search_equal_bulk(query = c("DTXSID7020182", "DTXSID9020112"))
#' }
ct_chemical_search_equal_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/search/equal/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000")),
    body_type = "raw_text"
  )

  return(result)
}
