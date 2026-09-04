#' Returns a list of substances whose monoisotopic mass falls within the specified range.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param lower_mass_limit Lower limit of the mass range to search for.
#' @param upper_mass_limit Upper limit of the mass range to search for.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_range_staging(lower_mass_limit = "DTXSID1024122")
#' }
chemi_amos_mass_range_staging <- function(lower_mass_limit = NULL, upper_mass_limit = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_mass_range_staging", "pre_request", list(params = list(`lower_mass_limit` = lower_mass_limit, `upper_mass_limit` = upper_mass_limit, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("lower_mass_limit" %in% names(req_data$params)) {
    lower_mass_limit <- req_data$params[["lower_mass_limit"]]
  }
  if ("upper_mass_limit" %in% names(req_data$params)) {
    upper_mass_limit <- req_data$params[["upper_mass_limit"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(upper_mass_limit)) options$upper_mass_limit <- upper_mass_limit
  result <- generic_chemi_request(
    query = lower_mass_limit,
    endpoint = "amos/mass_range_search/",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
