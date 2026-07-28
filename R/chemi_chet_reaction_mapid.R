#' List reactions for a map
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param map_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_mapid(map_id = "DTXSID7020182")
#' }
chemi_chet_reaction_mapid <- function(map_id = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_reaction_mapid",
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
  # Collect optional parameters
  options <- list()
  if (!is.null(map_id)) {
    options[['map_id']] <- map_id
  }
  result <- generic_request(
    endpoint = "reaction/mapid",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
