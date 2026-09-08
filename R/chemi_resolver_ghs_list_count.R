#' Resolver Ghs List Count
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_ghs_list_count()
#' }
chemi_resolver_ghs_list_count <- function() {
  result <- generic_request(
    endpoint = "resolver/ghs-list-count",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
