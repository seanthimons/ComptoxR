#' Get all predicted property options
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_name()
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_property_predicted_name <- function() {
  params <- base::list()
  result <- generic_request("endpoint" = "chemical/property/predicted/name", "method" = "GET", "batch_limit" = 0)
  result
}
