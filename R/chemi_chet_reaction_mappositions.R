#' Fetch stored reaction-map node positions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param map_id Primary query parameter. Type: string
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mappositions(map_id = "DTXSID7020182")
#' }
chemi_chet_reaction_mappositions <- function(map_id) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_reaction_mappositions",
    "pre_request",
    list(params = list(`map_id` = map_id, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("map_id" %in% names(req_data$params)) {
    map_id <- req_data$params[["map_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = map_id,
    endpoint = "reaction/mappositions/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
