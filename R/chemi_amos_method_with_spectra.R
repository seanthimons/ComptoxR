#' Returns information about a method with linked spectra, given an ID for either a spectrum or a method.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_method_with_spectra()
#' }
chemi_amos_method_with_spectra <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/method_with_spectra/",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


