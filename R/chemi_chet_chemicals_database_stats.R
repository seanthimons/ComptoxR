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
# Generated with apipak; do not edit by hand.
chemi_chet_chemicals_database_stats <- function(total = NULL) {
  params <- list("total" = total)
  result <- generic_request(
    "endpoint" = "chemicals/database/stats",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("total" = params[["total"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
