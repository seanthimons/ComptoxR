#' Counts the number of unique substances seen in a set of records.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_count_substances_in_ids()
#' }
chemi_amos_count_substances_in_ids <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "amos/count_substances_in_ids/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


