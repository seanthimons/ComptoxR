#' Resolver Ghs Hcodes
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
#' chemi_resolver_ghs_hcodes()
#' }
chemi_resolver_ghs_hcodes <- function() {
  result <- generic_request(
    endpoint = "resolver/ghs/hcodes",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
