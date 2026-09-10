#' List reactions for a map
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param map_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mapid(map_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_mapid <- function(map_id = NULL) {
  params <- list("map_id" = map_id)
  result <- generic_request(
    "endpoint" = "reaction/mapid",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("map_id" = params[["map_id"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
