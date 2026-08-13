#' Returns the number of spectra that have a specified methodology.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DTXSID for the substance of interest.
#' @param spectrum_type Analytical methodology to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_spectrum_count_for_methodology(dtxsid = "DTXSID1024122")
#' }
chemi_amos_spectrum_count_for_methodology <- function(dtxsid = NULL, spectrum_type = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_spectrum_count_for_methodology",
    "pre_request",
    list(params = list(`dtxsid` = dtxsid, `spectrum_type` = spectrum_type, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("dtxsid" %in% names(req_data$params)) {
    dtxsid <- req_data$params[["dtxsid"]]
  }
  if ("spectrum_type" %in% names(req_data$params)) {
    spectrum_type <- req_data$params[["spectrum_type"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(spectrum_type)) {
    options$spectrum_type <- spectrum_type
  }
  result <- generic_chemi_request(
    query = dtxsid,
    endpoint = "amos/spectrum_count_for_methodology/",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
