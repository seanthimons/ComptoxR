#' Get functional use categories
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_functional_use_category(query = "DTXSID7020182")
#' }
ct_exposure_functional_use_category <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/functional-use/category",
    method = "GET",
    batch_limit = 1
  )
}

