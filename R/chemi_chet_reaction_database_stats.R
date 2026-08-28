#' Reaction stats and filters
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param reaction_id Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database_stats(reaction_id = "DTXSID7020182")
#' }
chemi_chet_reaction_database_stats <- function(reaction_id = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_reaction_database_stats", "pre_request", list(params = list(`reaction_id` = reaction_id, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("reaction_id" %in% names(req_data$params)) {
    reaction_id <- req_data$params[["reaction_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(reaction_id)) options[['reaction_id']] <- reaction_id
    result <- generic_request(
    endpoint = "reaction/database/stats",
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
