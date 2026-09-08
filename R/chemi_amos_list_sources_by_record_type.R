#' Returns a list of all unique source names in the database for a specific record type.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_list_sources_by_record_type()
#' }
chemi_amos_list_sources_by_record_type <- function() {
  result <- generic_request(
    endpoint = "amos/list_sources_by_record_type/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
