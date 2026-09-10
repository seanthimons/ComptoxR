#' Retrieves a PDF from the database by the internal ID and type of record.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param record_type A string indicating which kind of record is being retrieved.  Valid values are 'fact sheet', 'method', and 'spectrum'.
#' @param internal_id Unique ID of the document of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_pdf(record_type = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_pdf <- function(record_type, internal_id = NULL) {
  params <- list("record_type" = record_type, "internal_id" = internal_id)
  result <- generic_request(
    "query" = params[["record_type"]],
    "endpoint" = "amos/get_pdf/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "path_params" = c("internal_id" = params[["internal_id"]])
  )
  result
}
