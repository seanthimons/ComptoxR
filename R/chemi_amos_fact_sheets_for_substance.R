#' Returns a list of fact sheet IDs that are associated with the given DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_fact_sheets_for_substance()
#' }
chemi_amos_fact_sheets_for_substance <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/fact_sheets_for_substance/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


