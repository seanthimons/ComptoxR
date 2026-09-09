#' Stdizer Workflows
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_workflows()
#' }
# Generated with apipak; do not edit by hand.
chemi_stdizer_workflows <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "stdizer/workflows",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
