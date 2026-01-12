#' Services Files
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_files(request = "DTXSID7020182")
#' }
chemi_services_files <- function(request) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request)) options[['request']] <- request
  generic_chemi_request(
    query = request,
    endpoint = "services/files",
    options = options,
    tidy = FALSE
  )
}


