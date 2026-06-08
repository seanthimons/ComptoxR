#' CTS Metabolizer Input Schema
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Returns the CTS metabolizer input schema and default transformation library
#' options.
#'
#' @param tidy Logical; if `TRUE`, convert the response to a tibble where
#'   possible. Defaults to `FALSE`.
#'
#' @return Parsed CTS metabolizer input metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' cts_metabolizer_inputs()
#' }
cts_metabolizer_inputs <- function(tidy = FALSE) {
  generic_cts_request(
    endpoint = "metabolizer/inputs",
    body = list(),
    method = "POST",
    tidy = tidy
  )
}
