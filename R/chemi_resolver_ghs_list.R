#' Resolver Ghs List
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_ghs_list(name = "DTXSID7020182")
#' }
chemi_resolver_ghs_list <- function(name) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_resolver_ghs_list", "pre_request", list(params = list(`name` = name, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("name" %in% names(req_data$params)) {
    name <- req_data$params[["name"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(name)) options[['name']] <- name
    result <- generic_request(
    endpoint = "resolver/ghs-list",
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
