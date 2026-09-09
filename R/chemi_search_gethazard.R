#' Search Gethazard
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param sid Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_search_gethazard(sid = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_search_gethazard <- function(sid) {
  params <- list("sid" = sid)
  result <- generic_request(
    "endpoint" = "search/gethazard",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("sid" = params[["sid"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
