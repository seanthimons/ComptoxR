#' Resolve a search-bar identifier to known substances.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param identifier Primary query parameter. Type: string
#' @return Returns a tibble with results (array of objects)
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_bar_resolver(identifier = "DTXSID7020182")
#' }
chemi_amos_bar_resolver <- function(identifier) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_bar_resolver", "pre_request", list(params = list(`identifier` = identifier, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("identifier" %in% names(req_data$params)) {
    identifier <- req_data$params[["identifier"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = identifier,
    endpoint = "amos/search_bar_resolver/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
