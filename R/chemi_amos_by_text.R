#' Retrieves a list of records from the ElasticSearch database that contain a searched substring
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param substr The substring to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_by_text(substr = "DTXSID7020182")
#' }
chemi_amos_by_text <- function(substr) {
  result <- generic_request(
    query = substr,
    endpoint = "amos/search_by_text/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
