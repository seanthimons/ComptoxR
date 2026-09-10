#' List details for a library
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param lib_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_details(lib_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_details <- function(lib_id = NULL) {
  params <- list("lib_id" = lib_id)
  result <- generic_request(
    "endpoint" = "reaction/details",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("lib_id" = params[["lib_id"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
