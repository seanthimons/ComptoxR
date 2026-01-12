#' Stdizer Chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param options Required parameter
#' @param chemicals Optional parameter
#' @param full Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_chemicals(options = "DTXSID7020182")
#' }
chemi_stdizer_chemicals <- function(options, chemicals = NULL, full = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(chemicals)) options$chemicals <- chemicals
  if (!is.null(full)) options$full <- full
  generic_chemi_request(
    query = options,
    endpoint = "stdizer/chemicals",
    options = options,
    tidy = FALSE
  )
}


