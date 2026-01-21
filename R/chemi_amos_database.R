#' Returns a summary of the records in the database, organized by record types, methodologies, and sources.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_database()
#' }
chemi_amos_database <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/database_summary/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


