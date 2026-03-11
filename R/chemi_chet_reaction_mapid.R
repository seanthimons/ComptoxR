#' List reactions for a map
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param map_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mapid(map_id = "DTXSID7020182")
#' }
chemi_chet_reaction_mapid <- function(map_id = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(map_id)) options[['map_id']] <- map_id
    result <- generic_request(
    endpoint = "reaction/mapid",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


