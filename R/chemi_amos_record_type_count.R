#' Returns the number of records of the given type.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param record_type Record type.  Accepted values are "analytical_qc", "fact_sheets", and "methods".
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_record_type_count(record_type = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_record_type_count <- function(record_type) {
  params <- list("record_type" = record_type)
  result <- generic_request(
    "query" = params[["record_type"]],
    "endpoint" = "amos/record_type_count/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
