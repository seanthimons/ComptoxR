#' Retrieves a list of fact sheets in the database with their supplemental information.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_fact_sheet_list()
#' }
chemi_amos_fact_sheet_list <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/fact_sheet_list",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


