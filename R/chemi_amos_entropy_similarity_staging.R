#' Calculates the entropy similarity for two spectra.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param spectrum_1 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param spectrum_2 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param type Type of mass window to use.  Should be either "da" or "ppm".
#' @param window Size of the mass window to use.  Will be in units of the 'type' argument.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_entropy_similarity_staging(spectrum_1 = "DTXSID1024122")
#' }
chemi_amos_entropy_similarity_staging <- function(spectrum_1 = NULL, spectrum_2 = NULL, type = NULL, window = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_entropy_similarity_staging", "pre_request", list(params = list(`spectrum_1` = spectrum_1, `spectrum_2` = spectrum_2, `type` = type, `window` = window, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("spectrum_1" %in% names(req_data$params)) {
    spectrum_1 <- req_data$params[["spectrum_1"]]
  }
  if ("spectrum_2" %in% names(req_data$params)) {
    spectrum_2 <- req_data$params[["spectrum_2"]]
  }
  if ("type" %in% names(req_data$params)) {
    type <- req_data$params[["type"]]
  }
  if ("window" %in% names(req_data$params)) {
    window <- req_data$params[["window"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(spectrum_2)) options$spectrum_2 <- spectrum_2
  if (!is.null(type)) options$type <- type
  if (!is.null(window)) options$window <- window
  result <- generic_chemi_request(
    query = spectrum_1,
    endpoint = "amos/entropy_similarity/",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
