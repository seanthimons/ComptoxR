#' Services Convert
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param content Required parameter
#' @param type Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_convert(content = "DTXSID7020182")
#' }
chemi_services_convert <- function(content, type = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(type)) options$type <- type
  generic_chemi_request(
    query = content,
    endpoint = "services/convert",
    options = options,
    tidy = FALSE
  )
}


