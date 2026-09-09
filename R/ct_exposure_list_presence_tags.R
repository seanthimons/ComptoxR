#' Get List Presence Tags
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_list_presence_tags()
#' }
# Generated with apipak; do not edit by hand.
ct_exposure_list_presence_tags <- function() {
  params <- list()
  result <- generic_request("endpoint" = "exposure/list-presence/tags", "method" = "GET", "batch_limit" = 0)
  result
}
