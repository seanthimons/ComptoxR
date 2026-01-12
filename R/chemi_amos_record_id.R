#' Searches for a record in the database by ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the record of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_id(internal_id = "DTXSID7020182")
#' }
chemi_amos_record_id <- function(internal_id) {
  generic_request(
    query = internal_id,
    endpoint = "amos/record_id_search/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


