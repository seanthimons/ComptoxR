#' Resolver Getannotation
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @param heading Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getannotation(name = "DTXSID7020182")
#' }
chemi_resolver_getannotation <- function(name, heading) {
  # Collect optional parameters
  options <- list()
  if (!is.null(name)) options[['name']] <- name
  if (!is.null(heading)) options[['heading']] <- heading
    result <- generic_request(
    query = NULL,
    endpoint = "resolver/getannotation",
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


