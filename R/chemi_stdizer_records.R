#' Stdizer Records
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param options Optional parameter
#' @param records Optional parameter
#' @param full Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_records(options = c("DTXSID90203381", "DTXSID301027109", "DTXSID3060245"))
#' }
chemi_stdizer_records <- function(options = NULL, records = NULL, full = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(records)) options$records <- records
  if (!is.null(full)) options$full <- full
  result <- generic_chemi_request(
    query = options,
    endpoint = "stdizer/records",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


