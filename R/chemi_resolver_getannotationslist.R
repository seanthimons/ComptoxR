#' Resolver Getannotationslist
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getannotationslist(name = "DTXSID7020182")
#' }
chemi_resolver_getannotationslist <- function(name) {
  # Collect optional parameters
  options <- list()
  if (!is.null(name)) options[['name']] <- name
    result <- generic_request(
    query = NULL,
    endpoint = "resolver/getannotationslist",
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


