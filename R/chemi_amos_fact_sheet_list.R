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
  generic_request(
    query = NULL,
    endpoint = "amos/fact_sheet_list",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


