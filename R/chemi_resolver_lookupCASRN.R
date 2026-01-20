#' Resolver lookupCASRN
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_lookupCASRN(query = "DTXSID7020182")
#' }
chemi_resolver_lookupCASRN <- function(query) {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
    result <- generic_request(
    query = NULL,
    endpoint = "resolver/lookupCASRN",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


