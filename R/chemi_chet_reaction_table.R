#' Fetch reaction detail table
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param reaction_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_table(reaction_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_table <- function(reaction_id = NULL) {
  params <- list("reaction_id" = reaction_id)
  result <- generic_request(
    "endpoint" = "reaction/table",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("reaction_id" = params[["reaction_id"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
