#' Resolver lookupCASRN
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_lookupCASRN(query = "DTXSID7020182")
#' }
chemi_resolver_lookupCASRN <- function(query) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_resolver_lookupCASRN",
    "pre_request",
    list(params = list(`query` = query, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) {
    options[['query']] <- query
  }
  result <- generic_request(
    endpoint = "resolver/lookupCASRN",
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
