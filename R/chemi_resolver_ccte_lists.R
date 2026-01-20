#' Resolver Ccte Lists
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_ccte_lists()
#' }
chemi_resolver_ccte_lists <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "resolver/ccte-lists",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


