#' Stdizer Records
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param full Optional parameter
#' @param options Optional parameter
#' @param records Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_records(full = "DTXSID1024122")
#' }
chemi_stdizer_records <- function(full = NULL, options = NULL, records = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(options)) {
    options$options <- options
  }
  if (!is.null(records)) {
    options$records <- records
  }
  result <- generic_chemi_request(
    query = full,
    endpoint = "stdizer/records",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
