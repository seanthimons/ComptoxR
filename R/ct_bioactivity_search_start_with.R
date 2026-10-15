#' Search by starting value
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param value Starting characters for search value. Type: string
#' @param top Optional parameter (default: 500)
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_search_start_with(value = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_search_start_with <- function(value, top = 500) {
  params <- base::list("value" = value, "top" = top)
  result <- generic_request(
    "query" = params[["value"]],
    "endpoint" = "bioactivity/search/start-with/",
    "method" = "GET",
    "batch_limit" = 1,
    "top" = params[["top"]]
  )
  result
}
