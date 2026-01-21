#' Stdizer Groups Recursive
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_recursive()
#' }
chemi_stdizer_groups_recursive <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "stdizer/groups/recursive",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


