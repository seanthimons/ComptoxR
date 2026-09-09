#' Returns a list of DTXSIDs for the given functional use.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param functional_class Functional use class.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_functional_class(functional_class = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_functional_class <- function(functional_class) {
  params <- list("functional_class" = functional_class)
  result <- generic_request(
    "query" = params[["functional_class"]],
    "endpoint" = "amos/functional_class_search/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
