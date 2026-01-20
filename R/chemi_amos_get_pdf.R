#' Retrieves a PDF from the database by the internal ID and type of record.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_pdf()
#' }
chemi_amos_get_pdf <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_pdf/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


