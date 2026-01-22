#' Calculates the spectral entropy for a single spectrum.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_spectral_entropy()
#' }
chemi_amos_spectral_entropy <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "amos/spectral_entropy/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


