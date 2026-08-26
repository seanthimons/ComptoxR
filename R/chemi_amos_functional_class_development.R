#' Returns a list of DTXSIDs for the given functional use.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param functional_class Functional use class.. Type: string
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_functional_class_development(functional_class = "DTXSID7020182")
#' }
chemi_amos_functional_class_development <- function(functional_class) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_functional_class_development", "pre_request", list(params = list(`functional_class` = functional_class, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("functional_class" %in% names(req_data$params)) {
    functional_class <- req_data$params[["functional_class"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = functional_class,
    endpoint = "amos/functional_class_search/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
