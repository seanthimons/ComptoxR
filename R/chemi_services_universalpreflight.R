#' Services Universalpreflight
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_universalpreflight()
#' }
chemi_services_universalpreflight <- function() {
  result <- generic_chemi_request(
    endpoint = "services/universalpreflight",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


