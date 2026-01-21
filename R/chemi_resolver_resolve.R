#' Resolver Resolve
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolve()
#' }
chemi_resolver_resolve <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "resolver/resolve",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


