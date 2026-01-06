#' Search by substring value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param value Substring of search word
#' @param top Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_contain(value = "DTXSID7020182")
#' }
ct_bioactivity_contain <- function(value, top = NULL) {
  generic_request(
    query = value,
    endpoint = "bioactivity/search/contain/",
    method = "GET",
    batch_limit = 1,
    top = top
  )
}

