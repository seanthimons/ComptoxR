#' Resolver Casharvest
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
#' chemi_resolver_casharvest(request = "DTXSID7020182")
#' }
chemi_resolver_casharvest <- function(request) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request)) options[['request']] <- request
  generic_chemi_request(
    query = request,
    endpoint = "resolver/casharvest",
    options = options,
    tidy = FALSE
  )
}


