#' Search by exact value
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param value Exact match of search value. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_search_equal(value = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_search_equal <- function(value) {
  params <- base::list("value" = value)
  result <- generic_request(
    "query" = params[["value"]],
    "endpoint" = "bioactivity/search/equal/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
