#' Services Files
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request.filesInfo Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_files(request.filesInfo = "DTXSID7020182")
#' }
chemi_services_files <- function(request.filesInfo = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request.filesInfo)) options[['request.filesInfo']] <- request.filesInfo
    result <- generic_chemi_request(
    endpoint = "services/files",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


