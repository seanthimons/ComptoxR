#' Returns an Excel file containing a deduplicated list of substances that appear in a given set of database record IDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_ids()
#' }
chemi_amos_substances_for_ids <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/substances_for_ids/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


