#' Chemical stats and library names
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param total Optional parameter
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database_stats(total = "DTXSID7020182")
#' }
chemi_chet_chemicals_database_stats <- function(total = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_chemicals_database_stats",
    "pre_request",
    list(params = list(`total` = total, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("total" %in% names(req_data$params)) {
    total <- req_data$params[["total"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(total)) {
    options[['total']] <- total
  }
  result <- generic_request(
    endpoint = "chemicals/database/stats",
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
