#' Returns substance(s) that match a search term.  Since some substance names can have slashes in them, <path> is used
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param search_term A substance identifier.  If it cannot be parsed as an InChIKey, CASRN, or DTXSID, it is assumed to be a name.. Type: string
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_substances_for_term_development(search_term = "DTXSID7020182")
#' }
chemi_amos_get_substances_for_term_development <- function(search_term) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_get_substances_for_term_development", "pre_request", list(params = list(`search_term` = search_term, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("search_term" %in% names(req_data$params)) {
    search_term <- req_data$params[["search_term"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = search_term,
    endpoint = "amos/get_substances_for_search_term/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
