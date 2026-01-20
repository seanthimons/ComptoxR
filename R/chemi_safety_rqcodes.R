#' Safety Rqcodes
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_safety_rqcodes()
#' }
chemi_safety_rqcodes <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "safety/rqcodes",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


