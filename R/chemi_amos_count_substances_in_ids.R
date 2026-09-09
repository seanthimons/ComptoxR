#' Counts the number of unique substances seen in a set of records.
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
#' chemi_amos_count_substances_in_ids(internal_id_list = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_count_substances_in_ids <- function(internal_id_list = NULL) {
  params <- list("internal_id_list" = internal_id_list)
  result <- generic_chemi_request(
    "query" = params[["internal_id_list"]],
    "endpoint" = "amos/count_substances_in_ids/",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
