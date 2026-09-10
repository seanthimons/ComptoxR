#' Returns an Excel file containing a deduplicated list of substances that appear in a given set of database record IDs.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_id_list Array of record IDs.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_ids(internal_id_list = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_substances_for_ids <- function(internal_id_list = NULL) {
  params <- list("internal_id_list" = internal_id_list)
  result <- generic_chemi_request(
    "query" = params[["internal_id_list"]],
    "endpoint" = "amos/substances_for_ids/",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
