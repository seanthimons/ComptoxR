#' Get all Media options
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_mediums()
#' }
# Generated with apipak; do not edit by hand.
ct_exposure_mmdb_mediums <- function() {
  params <- list()
  result <- generic_request("endpoint" = "exposure/mmdb/mediums", "method" = "GET", "batch_limit" = 0)
  result
}
