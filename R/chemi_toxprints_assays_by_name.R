#' Toxprints Assays
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param name Primary query parameter. Type: string
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_by_name(name = "DTXSID7020182")
#' }
chemi_toxprints_assays_by_name <- function(name) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_toxprints_assays_by_name",
    "pre_request",
    list(params = list(`name` = name, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("name" %in% names(req_data$params)) {
    name <- req_data$params[["name"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = name,
    endpoint = "toxprints/assays/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
