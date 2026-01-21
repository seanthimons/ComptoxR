#' Stdizer Groups Preflight
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_groups_preflight()
#' }
chemi_stdizer_groups_preflight <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "stdizer/groups/preflight",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


