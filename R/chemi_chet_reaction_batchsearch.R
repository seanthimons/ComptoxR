#' Batch search reactions and chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids Required parameter
#' @param search_level Required parameter. Options: chemical, reaction
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_batchsearch(dtxsids = "DTXSID1024122")
#' }
chemi_chet_reaction_batchsearch <- function(dtxsids, search_level) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_reaction_batchsearch",
    "pre_request",
    list(params = list(`dtxsids` = dtxsids, `search_level` = search_level, `chemicals` = chemicals, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsids" %in% names(req_data$params)) {
    dtxsids <- req_data$params[["dtxsids"]]
  }
  if ("search_level" %in% names(req_data$params)) {
    search_level <- req_data$params[["search_level"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  options$search_level <- search_level
  result <- generic_chemi_request(
    server = server,
    query = dtxsids,
    endpoint = "reaction/batchsearch",
    options = options,
    tidy = FALSE,
    chemicals = chemicals
  )

  # Additional post-processing can be added here

  return(result)
}
