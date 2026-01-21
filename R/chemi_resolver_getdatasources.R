#' Resolver Getdatasources
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getdatasources()
#' }
chemi_resolver_getdatasources <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "resolver/getdatasources",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


