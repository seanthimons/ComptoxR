#' Check whether an identifier represents an unknown SMILES.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param identifier Primary query parameter. Type: string
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_check_if_similar_smiles(identifier = "DTXSID7020182")
#' }
chemi_amos_check_if_similar_smiles <- function(identifier) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_check_if_similar_smiles", "pre_request", list(params = list(`identifier` = identifier, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("identifier" %in% names(req_data$params)) {
    identifier <- req_data$params[["identifier"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = identifier,
    endpoint = "amos/check_if_similar_smiles/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
