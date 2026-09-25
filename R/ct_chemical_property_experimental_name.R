#' Get all experimental property options
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_property_experimental_name()
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_property_experimental_name <- function() {
  params <- base::list()
  result <- generic_request("endpoint" = "chemical/property/experimental/name", "method" = "GET", "batch_limit" = 0)
  result
}
