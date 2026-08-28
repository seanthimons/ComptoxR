#' List maps for a reaction
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param react_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_react_maps(react_id = "DTXSID7020182")
#' }
chemi_chet_reaction_react_maps <- function(react_id = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_reaction_react_maps", "pre_request", list(params = list(`react_id` = react_id, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("react_id" %in% names(req_data$params)) {
    react_id <- req_data$params[["react_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(react_id)) options[['react_id']] <- react_id
    result <- generic_request(
    endpoint = "reaction/react_maps",
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
