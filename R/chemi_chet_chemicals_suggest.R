#' Suggest CheT chemicals for look-ahead search
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query User-entered chemical name, DTXSID, CASRN, or resolver-supported identifier.
#' @param limit Optional parameter (default: 8)
#' @param only_in_reactions If true, only suggest chemicals that participate in at least one reaction. (default: true)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_suggest(query = "DTXSID7020182")
#' }
chemi_chet_chemicals_suggest <- function(query, limit = 8, only_in_reactions = "true") {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_chemicals_suggest", "pre_request", list(params = list(`query` = query, `limit` = limit, `only_in_reactions` = only_in_reactions, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("limit" %in% names(req_data$params)) {
    limit <- req_data$params[["limit"]]
  }
  if ("only_in_reactions" %in% names(req_data$params)) {
    only_in_reactions <- req_data$params[["only_in_reactions"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(limit)) options[['limit']] <- limit
  if (!is.null(only_in_reactions)) options[['only_in_reactions']] <- only_in_reactions
    result <- generic_request(
    endpoint = "chemicals/suggest",
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
