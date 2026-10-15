#' Search by substring value
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param value Substring of search word. Type: string
#' @param top Optional parameter (default: 0)
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_search_contain(value = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_search_contain <- function(value, top = 0) {
  params <- base::list("value" = value, "top" = top)
  result <- generic_request(
    "query" = params[["value"]],
    "endpoint" = "bioactivity/search/contain/",
    "method" = "GET",
    "batch_limit" = 1,
    "top" = params[["top"]]
  )
  result
}
