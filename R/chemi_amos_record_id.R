#' Searches for a record in the database by ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_record_id()
#' }
chemi_amos_record_id <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/record_id_search/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


