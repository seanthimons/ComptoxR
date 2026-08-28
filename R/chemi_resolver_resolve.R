#' Resolver Resolve
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param mol Optional parameter
#' @param queries Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolve(mol = "DTXSID1024122")
#' }
chemi_resolver_resolve <- function(mol = NULL, queries = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_resolver_resolve", "pre_request", list(params = list(`mol` = mol, `queries` = queries, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("mol" %in% names(req_data$params)) {
    mol <- req_data$params[["mol"]]
  }
  if ("queries" %in% names(req_data$params)) {
    queries <- req_data$params[["queries"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(queries)) options$queries <- queries
  result <- generic_chemi_request(
    query = mol,
    endpoint = "resolver/resolve",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
