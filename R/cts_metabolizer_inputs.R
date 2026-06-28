#' Metabolizer input schema
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemical Optional parameter (default: CCCC)
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' cts_metabolizer_inputs(chemical = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
cts_metabolizer_inputs <- function(chemical = "CCCC") {
  # Build request body
  body <- list()
  if (!is.null(chemical)) {
    body$chemical <- chemical
  }

  result <- generic_cts_request(
    endpoint = "metabolizer/inputs",
    body = body,
    method = "POST",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
