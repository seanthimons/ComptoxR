#' Services Cim Component Info
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_services_cim_component_info()
#' }
# Generated with apipak; do not edit by hand.
chemi_services_cim_component_info <- function() {
  params <- list()
  result <- generic_request(
    "endpoint" = "services/cim_component_info",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
