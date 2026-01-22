#' Stdizer Records
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_records()
#' }
chemi_stdizer_records <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "stdizer/records",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


