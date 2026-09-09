#' Returns a list of all unique source names in the database for a specific record type.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_list_sources_by_record_type()
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_list_sources_by_record_type <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "amos/list_sources_by_record_type/",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
