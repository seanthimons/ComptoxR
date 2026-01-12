#' Stdizer Records
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param options Required parameter
#' @param records Optional parameter
#' @param full Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_records(options = "DTXSID7020182")
#' }
chemi_stdizer_records <- function(options, records = NULL, full = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(records)) options$records <- records
  if (!is.null(full)) options$full <- full
  generic_chemi_request(
    query = options,
    endpoint = "stdizer/records",
    options = options,
    tidy = FALSE
  )
}


