#' Find highlighted substring matches in a document.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param record_type Primary query parameter. Type: string
#' @param internal_id Optional parameter. Type: string
#' @param substr Optional parameter. Type: string
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_find_matches(record_type = "DTXSID7020182")
#' }
chemi_amos_find_matches <- function(record_type, internal_id = NULL, substr = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_find_matches", "pre_request", list(params = list(`record_type` = record_type, `internal_id` = internal_id, `substr` = substr, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("record_type" %in% names(req_data$params)) {
    record_type <- req_data$params[["record_type"]]
  }
  if ("internal_id" %in% names(req_data$params)) {
    internal_id <- req_data$params[["internal_id"]]
  }
  if ("substr" %in% names(req_data$params)) {
    substr <- req_data$params[["substr"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = record_type,
    endpoint = "amos/find_matches/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(internal_id = internal_id, substr = substr)
  )

  # Additional post-processing can be added here

  return(result)
}
