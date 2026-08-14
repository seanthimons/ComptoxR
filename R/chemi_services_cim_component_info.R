#' Services Cim Component Info
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_cim_component_info()
#' }
chemi_services_cim_component_info <- function() {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_services_cim_component_info", "pre_request", list(params = list(`server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    endpoint = "services/cim_component_info",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
