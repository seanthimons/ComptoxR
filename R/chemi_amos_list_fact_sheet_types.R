#' Returns a list of all unique fact sheet types, coming from the document_type field of the fact sheet table.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_list_fact_sheet_types()
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_list_fact_sheet_types <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "amos/list_fact_sheet_types/",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
