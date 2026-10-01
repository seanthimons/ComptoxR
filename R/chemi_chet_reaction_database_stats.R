#' Reaction stats and filters
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param reaction_id Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database_stats(reaction_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_database_stats <- function(reaction_id = NULL) {
  params <- base::list("reaction_id" = reaction_id)
  result <- generic_request(
    "endpoint" = "reaction/database/stats",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("reaction_id" = params[["reaction_id"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
