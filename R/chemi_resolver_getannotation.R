#' Resolver Getannotation
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Required parameter
#' @param heading Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getannotation(name = "DTXSID7020182")
#' }
chemi_resolver_getannotation <- function(name, heading) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_resolver_getannotation", "pre_request", list(params = list(`name` = name, `heading` = heading, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("name" %in% names(req_data$params)) {
    name <- req_data$params[["name"]]
  }
  if ("heading" %in% names(req_data$params)) {
    heading <- req_data$params[["heading"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(name)) options[['name']] <- name
  if (!is.null(heading)) options[['heading']] <- heading
    result <- generic_request(
    endpoint = "resolver/getannotation",
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
