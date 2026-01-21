#' Resolver Casharvest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request.filesInfo Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_casharvest(request.filesInfo = "DTXSID7020182")
#' }
chemi_resolver_casharvest <- function(request.filesInfo) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request.filesInfo)) options[['request.filesInfo']] <- request.filesInfo
    result <- generic_chemi_request(
    query = NULL,
    endpoint = "resolver/casharvest",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


