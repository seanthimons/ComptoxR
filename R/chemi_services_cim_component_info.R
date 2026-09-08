#' Services Cim Component Info
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_services_cim_component_info()
#' }
chemi_services_cim_component_info <- function() {
  result <- generic_request(
    endpoint = "services/cim_component_info",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
