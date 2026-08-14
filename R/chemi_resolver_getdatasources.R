#' Resolver Getdatasources
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getdatasources()
#' }
chemi_resolver_getdatasources <- function() {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_resolver_getdatasources", "pre_request", list(params = list(`server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    endpoint = "resolver/getdatasources",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
