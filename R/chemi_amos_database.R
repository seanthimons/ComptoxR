#' Returns a summary of the records in the database, organized by record types, methodologies, and sources.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_database()
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_database <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "amos/database_summary/",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
