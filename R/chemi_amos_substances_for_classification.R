#' Returns a list of substances in the database which match the specified top four levels of a ClassyFire classification.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_classification()
#' }
chemi_amos_substances_for_classification <- function() {
  result <- generic_chemi_request(
    endpoint = "amos/substances_for_classification/",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


