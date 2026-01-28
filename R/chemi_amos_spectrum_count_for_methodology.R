#' Returns the number of spectra that have a specified methodology.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_spectrum_count_for_methodology()
#' }
chemi_amos_spectrum_count_for_methodology <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/spectrum_count_for_methodology/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


