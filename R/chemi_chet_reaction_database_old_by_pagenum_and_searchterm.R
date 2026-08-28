#' Search reactions (legacy)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param pagenum Primary query parameter. Type: integer
#' @param searchterm Optional parameter. Type: string
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database_old_by_pagenum_and_searchterm(pagenum = "DTXSID7020182")
#' }
chemi_chet_reaction_database_old_by_pagenum_and_searchterm <- function(pagenum, searchterm = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_reaction_database_old_by_pagenum_and_searchterm", "pre_request", list(params = list(`pagenum` = pagenum, `searchterm` = searchterm, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("pagenum" %in% names(req_data$params)) {
    pagenum <- req_data$params[["pagenum"]]
  }
  if ("searchterm" %in% names(req_data$params)) {
    searchterm <- req_data$params[["searchterm"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = pagenum,
    endpoint = "reaction/database-old/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(searchterm = searchterm)
  )

  # Additional post-processing can be added here

  return(result)
}
