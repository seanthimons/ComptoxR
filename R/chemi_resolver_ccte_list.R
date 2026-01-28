#' Resolver Ccte List
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
#' chemi_resolver_ccte_list(name = "DTXSID7020182")
#' }
chemi_resolver_ccte_list <- function(name) {
  # Collect optional parameters
  options <- list()
  if (!is.null(name)) options[['name']] <- name
    result <- generic_request(
    endpoint = "resolver/ccte-list",
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


