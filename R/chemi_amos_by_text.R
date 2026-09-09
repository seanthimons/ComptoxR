#' Retrieves a list of records from the ElasticSearch database that contain a searched substring
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param substr The substring to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_by_text(substr = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_by_text <- function(substr) {
  params <- list("substr" = substr)
  result <- generic_request(
    "query" = params[["substr"]],
    "endpoint" = "amos/search_by_text/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
