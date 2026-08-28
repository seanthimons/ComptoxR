#' Returns information on substances where the specified substring is in or equal to a name.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param substring A name substring to search by.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substring(substring = "DTXSID7020182")
#' }
chemi_amos_substring <- function(substring) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_substring", "pre_request", list(params = list(`substring` = substring, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("substring" %in% names(req_data$params)) {
    substring <- req_data$params[["substring"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = substring,
    endpoint = "amos/substring_search/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
