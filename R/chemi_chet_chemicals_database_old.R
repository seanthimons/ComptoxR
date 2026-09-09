#' List all chemicals (legacy)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database_old()
#' }
# Generated with apipak; do not edit by hand.
chemi_chet_chemicals_database_old <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "chemicals/database-old",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
