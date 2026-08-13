#' Returns information about a method with linked spectra, given an ID for either a spectrum or a method.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param search_type How to search the database.  Valid values are "spectrum" and "method".
#' @param internal_id Unique ID of the spectrum or method of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_method_with_spectra(search_type = "DTXSID7020182")
#' }
chemi_amos_method_with_spectra <- function(search_type, internal_id = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_method_with_spectra",
    "pre_request",
    list(params = list(`search_type` = search_type, `internal_id` = internal_id, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("search_type" %in% names(req_data$params)) {
    search_type <- req_data$params[["search_type"]]
  }
  if ("internal_id" %in% names(req_data$params)) {
    internal_id <- req_data$params[["internal_id"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = search_type,
    endpoint = "amos/method_with_spectra/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(internal_id = internal_id)
  )

  # Additional post-processing can be added here

  return(result)
}
