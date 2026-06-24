#' Fetch stored reaction-map node positions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param map_id Primary query parameter. Type: string
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mappositions(map_id = "DTXSID7020182")
#' }
chemi_chet_reaction_mappositions <- function(map_id) {
  result <- generic_request(
    query = map_id,
    endpoint = "reaction/mappositions/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


