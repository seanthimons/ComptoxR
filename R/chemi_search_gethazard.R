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
# Generated with specmill; do not edit by hand.
chemi_search_gethazard <- function(sid) {
  params <- base::list("sid" = sid)
  result <- generic_request(
    "endpoint" = "search/gethazard",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("sid" = params[["sid"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
