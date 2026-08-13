#' Returns lists of documents, each of which contain at least one substance of sufficient similarity to the searched
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param identifier_type Primary query parameter
#' @param identifier Optional parameter
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_similar_structures_by_identifier_type_and_identifier(identifier_type = "DTXSID7020182")
#' }
chemi_amos_get_similar_structures_by_identifier_type_and_identifier <- function(identifier_type, identifier = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_get_similar_structures_by_identifier_type_and_identifier",
    "pre_request",
    list(params = list(`identifier_type` = identifier_type, `identifier` = identifier, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("identifier_type" %in% names(req_data$params)) {
    identifier_type <- req_data$params[["identifier_type"]]
  }
  if ("identifier" %in% names(req_data$params)) {
    identifier <- req_data$params[["identifier"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = identifier_type,
    endpoint = "amos/get_similar_structures/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(identifier = identifier)
  )

  # Additional post-processing can be added here

  return(result)
}
