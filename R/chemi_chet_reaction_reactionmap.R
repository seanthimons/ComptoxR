#' Build reaction map
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param id Optional parameter
#' @param searchtype Optional parameter
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_reactionmap(id = "DTXSID7020182")
#' }
chemi_chet_reaction_reactionmap <- function(id = NULL, searchtype = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_reaction_reactionmap",
    "pre_request",
    list(params = list(`id` = id, `searchtype` = searchtype, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("id" %in% names(req_data$params)) {
    id <- req_data$params[["id"]]
  }
  if ("searchtype" %in% names(req_data$params)) {
    searchtype <- req_data$params[["searchtype"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(id)) {
    options[['id']] <- id
  }
  if (!is.null(searchtype)) {
    options[['searchtype']] <- searchtype
  }
  result <- generic_request(
    endpoint = "reaction/reactionmap",
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
