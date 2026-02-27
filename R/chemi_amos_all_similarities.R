#' Given a list of DTXSIDs and a list of mass spectra, return a highest similarity score for each combination of DTXSID and spectrum.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param da_window Mass window in units of daltons.  If not null, this will be used for similarity calculations, regardless of whether ppm_window is supplied.
#' @param dtxsids List of DTXSIDs to search for.
#' @param min_intensity Minimum intensity level for peaks in both the user and database spectra to consider.  All database spectra are scaled to have a maximum intensity of 100, and all user spectra are assumed to be scaled the same.
#' @param ms_level Level of mass spectrometry; if supplied, then only spectra at the specified level will be returned.  Valid values are from 1 to 5.
#' @param ppm_window Mass window in units of parts per million.  Will only be used if da_window is null or not passed and ppm_window is not null.
#' @param spectra A list of spectra, where each spectrum is an array of m/z-intensity pairs formatted as two-element arrays.  Maximum intensity should be scaled to 100.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_all_similarities(da_window = "DTXSID7020182")
#' }
chemi_amos_all_similarities <- function(da_window = NULL, dtxsids = NULL, min_intensity = NULL, ms_level = NULL, ppm_window = NULL, spectra = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(dtxsids)) options$dtxsids <- dtxsids
  if (!is.null(min_intensity)) options$min_intensity <- min_intensity
  if (!is.null(ms_level)) options$ms_level <- ms_level
  if (!is.null(ppm_window)) options$ppm_window <- ppm_window
  if (!is.null(spectra)) options$spectra <- spectra
  result <- generic_chemi_request(
    query = da_window,
    endpoint = "amos/all_similarities_by_dtxsid/",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


