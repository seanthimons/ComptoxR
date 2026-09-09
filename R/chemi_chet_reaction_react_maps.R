#' List maps for a reaction
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param react_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_react_maps(react_id = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_chet_reaction_react_maps <- function(react_id = NULL) {
  params <- list("react_id" = react_id)
  result <- generic_request(
    "endpoint" = "reaction/react_maps",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("react_id" = params[["react_id"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
