#' Returns all substances associated with the specified functional use classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param functional_use Functional use classification to search for.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids_from_functional_use(functional_use = "DTXSID7020182")
#' }
chemi_amos_dtxsids_from_functional_use <- function(functional_use) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_dtxsids_from_functional_use",
    "pre_request",
    list(params = list(`functional_use` = functional_use, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("functional_use" %in% names(req_data$params)) {
    functional_use <- req_data$params[["functional_use"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = functional_use,
    endpoint = "amos/dtxsids_from_functional_use/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
