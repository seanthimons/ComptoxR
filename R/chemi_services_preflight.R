#' Services Preflight
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_preflight()
#' }
chemi_services_preflight <- function() {
  result <- generic_chemi_request(
    endpoint = "services/preflight",
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


