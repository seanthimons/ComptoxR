#' Retrieves a list of records from the database that contain a searched DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos()
#' }
chemi_amos <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/search/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


