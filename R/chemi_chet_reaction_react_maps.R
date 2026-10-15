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
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_react_maps <- function(react_id = NULL) {
  params <- base::list("react_id" = react_id)
  result <- generic_request(
    "endpoint" = "reaction/react_maps",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("react_id" = params[["react_id"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
