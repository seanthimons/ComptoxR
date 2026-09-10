#' Fetch stored reaction-map node positions
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param map_id Primary query parameter. Type: string
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mappositions(map_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_mappositions <- function(map_id) {
  params <- list("map_id" = map_id)
  result <- generic_request(
    "query" = params[["map_id"]],
    "endpoint" = "reaction/mappositions/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
