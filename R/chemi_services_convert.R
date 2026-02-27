#' Services Convert
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param content Optional parameter
#' @param type Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_convert(content = "DTXSID7020182")
#' }
chemi_services_convert <- function(content = NULL, type = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(type)) options$type <- type
  result <- generic_chemi_request(
    query = content,
    endpoint = "services/convert",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


