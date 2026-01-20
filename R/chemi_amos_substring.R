#' Returns information on substances where the specified substring is in or equal to a name.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substring()
#' }
chemi_amos_substring <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/substring_search/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


