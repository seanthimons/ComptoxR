#' Services Caspreflight
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_caspreflight()
#' }
chemi_services_caspreflight <- function() {
  result <- generic_chemi_request(
    endpoint = "services/caspreflight",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


