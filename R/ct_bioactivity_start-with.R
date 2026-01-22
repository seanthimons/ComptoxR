#' Search by starting value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param value Starting characters for search value
#' @param top Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_start_with(value = "DTXSID7020182")
#' }
ct_bioactivity_start_with <- function(value, top = NULL) {
  generic_request(
    query = value,
    endpoint = "bioactivity/search/start-with/",
    method = "GET",
    batch_limit = 1,
    top = top
  )
}

