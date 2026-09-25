#' Get all list types
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_type()
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_type <- function() {
  params <- base::list()
  result <- generic_request("endpoint" = "chemical/list/type", "method" = "GET", "batch_limit" = 0)
  result
}
