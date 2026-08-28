#' Given a list of DTXSIDs, return all mass spectra for those substances.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsids List of DTXSIDs to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectra_for_substances(dtxsids = "DTXSID1024122")
#' }
chemi_amos_mass_spectra_for_substances <- function(dtxsids = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_mass_spectra_for_substances", "pre_request", list(params = list(`dtxsids` = dtxsids, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsids" %in% names(req_data$params)) {
    dtxsids <- req_data$params[["dtxsids"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = dtxsids,
    endpoint = "amos/mass_spectra_for_substances/",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
