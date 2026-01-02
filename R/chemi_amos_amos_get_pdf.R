#' Retrieves a PDF from the database by the internal ID and type of record.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param internal_id Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_amos_get_pdf(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_pdf <- function(query, internal_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(internal_id)) options$internal_id <- internal_id

  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_pdf/",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}