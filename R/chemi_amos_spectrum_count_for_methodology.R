#' Returns the number of spectra that have a specified methodology.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DTXSID for the substance of interest.
#' @param spectrum_type Analytical methodology to search for.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_spectrum_count_for_methodology(dtxsid = c("DTXSID4048141", "DTXSID60570416", "DTXSID1034187"))
#' }
chemi_amos_spectrum_count_for_methodology <- function(dtxsid = NULL, spectrum_type = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(spectrum_type)) options$spectrum_type <- spectrum_type
  result <- generic_chemi_request(
    query = dtxsid,
    endpoint = "amos/spectrum_count_for_methodology/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


