#' CTS Metabolizer Endpoints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Returns CTS metabolizer endpoint metadata.
#'
#' @param tidy Logical; if `TRUE`, convert the response to a tibble where
#'   possible. Defaults to `FALSE`.
#'
#' @return Parsed CTS metabolizer endpoint metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' cts_metabolizer()
#' }
cts_metabolizer <- function(tidy = FALSE) {
  generic_cts_request(
    endpoint = "metabolizer",
    method = "GET",
    tidy = tidy
  )
}
