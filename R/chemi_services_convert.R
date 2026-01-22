#' Services Convert
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_convert()
#' }
chemi_services_convert <- function() {
  result <- generic_chemi_request(
    query = NULL,
    endpoint = "services/convert",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


