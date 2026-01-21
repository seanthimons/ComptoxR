#' Returns general information about a record by ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_info_by_id()
#' }
chemi_amos_get_info_by_id <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_info_by_id/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


