#' Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints(smiles = "DTXSID7020182")
#' }
chemi_toxprints <- function(smiles, headers = FALSE, profile = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_toxprints", "pre_request", list(params = list(`smiles` = smiles, `headers` = headers, `profile` = profile, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("headers" %in% names(req_data$params)) {
    headers <- req_data$params[["headers"]]
  }
  if ("profile" %in% names(req_data$params)) {
    profile <- req_data$params[["profile"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(headers)) options[['headers']] <- headers
  if (!is.null(profile)) options[['profile']] <- profile
    result <- generic_request(
    endpoint = "toxprints",
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

#' Toxprints
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_bulk(query = "DTXSID1024122")
#' }
chemi_toxprints_bulk <- function(query) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_toxprints_bulk", "pre_request", list(params = list(`query` = query, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = query,
    endpoint = "toxprints",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100")),
    server = server
  )

  return(result)
}
