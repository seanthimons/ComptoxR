#' Search reactions and chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Optional parameter
#' @param searchType Optional parameter
#' @param substringTF Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction(query = "DTXSID7020182")
#' }
chemi_chet_reaction <- function(query = NULL, searchType = NULL, substringTF = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_reaction",
    "pre_request",
    list(params = list(`query` = query, `searchType` = searchType, `substringTF` = substringTF, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("searchType" %in% names(req_data$params)) {
    searchType <- req_data$params[["searchType"]]
  }
  if ("substringTF" %in% names(req_data$params)) {
    substringTF <- req_data$params[["substringTF"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) {
    options[['query']] <- query
  }
  if (!is.null(searchType)) {
    options[['searchType']] <- searchType
  }
  if (!is.null(substringTF)) {
    options[['substringTF']] <- substringTF
  }
  result <- generic_request(
    endpoint = "reaction/search",
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
