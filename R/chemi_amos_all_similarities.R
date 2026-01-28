#' Given a list of DTXSIDs and a list of mass spectra, return a highest similarity score for each combination of DTXSID and spectrum.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_all_similarities()
#' }
chemi_amos_all_similarities <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/all_similarities_by_dtxsid/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


