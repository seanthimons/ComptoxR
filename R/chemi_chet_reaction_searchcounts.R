#' Count search results
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param search_input Primary query parameter. Type: string
#' @param search_type Optional parameter. Type: string
#' @return Returns a tibble with results (array of objects)
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_searchcounts(search_input = "DTXSID7020182")
#' }
chemi_chet_reaction_searchcounts <- function(search_input, search_type = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_reaction_searchcounts",
    "pre_request",
    list(params = list(`search_input` = search_input, `search_type` = search_type, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("search_input" %in% names(req_data$params)) {
    search_input <- req_data$params[["search_input"]]
  }
  if ("search_type" %in% names(req_data$params)) {
    search_type <- req_data$params[["search_type"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = search_input,
    endpoint = "reaction/searchcounts/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(search_type = search_type)
  )

  # Additional post-processing can be added here

  return(result)
}
