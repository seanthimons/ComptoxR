#' Returns a list of categories for the specified level of ClassyFire classification, given the higher levels of classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_next_level_classification()
#' }
chemi_amos_next_level_classification <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/next_level_classification/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


