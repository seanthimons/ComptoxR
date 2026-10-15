#' Get functional use categories
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_functional_use_category()
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_functional_use_category <- function() {
  params <- base::list()
  result <- generic_request("endpoint" = "exposure/functional-use/category", "method" = "GET", "batch_limit" = 0)
  result
}
