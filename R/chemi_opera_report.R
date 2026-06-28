#' Generate a standalone OPERA calculation report
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox substance identifier
#' @param modelId Dashboard model ID for the OPERA endpoint
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_opera_report(dtxsid = "DTXSID7020182")
#' }
chemi_opera_report <- function(dtxsid, modelId) {
  # Collect optional parameters
  options <- list()
  if (!is.null(dtxsid)) {
    options[['dtxsid']] <- dtxsid
  }
  if (!is.null(modelId)) {
    options[['modelId']] <- modelId
  }
  result <- generic_request(
    endpoint = "opera/report",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
