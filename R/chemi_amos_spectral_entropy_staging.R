#' Calculates the spectral entropy for a single spectrum.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param spectrum Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_spectral_entropy_staging(spectrum = "DTXSID1024122")
#' }
chemi_amos_spectral_entropy_staging <- function(spectrum = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amos_spectral_entropy_staging", "pre_request", list(params = list(`spectrum` = spectrum, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("spectrum" %in% names(req_data$params)) {
    spectrum <- req_data$params[["spectrum"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = spectrum,
    endpoint = "amos/spectral_entropy/",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
