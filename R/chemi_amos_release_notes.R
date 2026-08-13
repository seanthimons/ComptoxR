#' Returns a list of release notes for AMOS.
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
#' chemi_amos_release_notes()
#' }
chemi_amos_release_notes <- function() {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_release_notes", "pre_request", list(params = list(`server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    endpoint = "amos/release_notes",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
