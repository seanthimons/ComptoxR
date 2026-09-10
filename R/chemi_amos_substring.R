#' Returns information on substances where the specified substring is in or equal to a name.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param substring A name substring to search by.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_substring(substring = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_substring <- function(substring) {
  params <- list("substring" = substring)
  result <- generic_request(
    "query" = params[["substring"]],
    "endpoint" = "amos/substring_search/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
