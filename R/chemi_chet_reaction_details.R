#' List details for a library
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lib_id Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_details(lib_id = "DTXSID7020182")
#' }
chemi_chet_reaction_details <- function(lib_id = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_chet_reaction_details",
    "pre_request",
    list(params = list(`lib_id` = lib_id, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("lib_id" %in% names(req_data$params)) {
    lib_id <- req_data$params[["lib_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(lib_id)) {
    options[['lib_id']] <- lib_id
  }
  result <- generic_request(
    endpoint = "reaction/details",
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
