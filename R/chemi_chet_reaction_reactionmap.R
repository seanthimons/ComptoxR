#' Build reaction map
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id Optional parameter
#' @param searchtype Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_reactionmap(id = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_chet_reaction_reactionmap <- function(id = NULL, searchtype = NULL) {
  params <- list("id" = id, "searchtype" = searchtype)
  result <- generic_request(
    "endpoint" = "reaction/reactionmap",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("id" = params[["id"]], "searchtype" = params[["searchtype"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
