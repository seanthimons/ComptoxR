#' Endpoint for retrieving a specified NMR spectrum from the database.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the NMR spectrum of interest.. Type: string
#' @return Returns a tibble with results
#' @apiStage development
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_nmr_spectrum_development(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_nmr_spectrum_development <- function(internal_id) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_get_nmr_spectrum_development", "pre_request", list(params = list(`internal_id` = internal_id, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("internal_id" %in% names(req_data$params)) {
    internal_id <- req_data$params[["internal_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = internal_id,
    endpoint = "amos/get_nmr_spectrum/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
