#' Chemical stats and library names
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param total Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database_stats(total = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_database_stats <- function(total = NULL) {
  params <- base::list("total" = total)
  result <- generic_request(
    "endpoint" = "chemicals/database/stats",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("total" = params[["total"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
