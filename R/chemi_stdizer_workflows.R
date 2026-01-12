#' Stdizer Workflows
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_workflows()
#' }
chemi_stdizer_workflows <- function() {
  generic_request(
    query = NULL,
    endpoint = "stdizer/workflows",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


