#' Returns a list of DTXSIDs associated with the specified internal ID, along with additional substance information.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_find_dtxsids()
#' }
chemi_amos_find_dtxsids <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/find_dtxsids/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


