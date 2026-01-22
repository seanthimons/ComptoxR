#' Calculates the entropy similarity for two spectra.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_entropy_similarity()
#' }
chemi_amos_entropy_similarity <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "amos/entropy_similarity/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


