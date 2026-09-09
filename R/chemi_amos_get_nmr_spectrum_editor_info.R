#' Retrieves metadata from the database about a single NMR spectrum.  It is currently intended only to retrieve
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_id Unique ID of the NMR spectrum.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_nmr_spectrum_editor_info(internal_id = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_get_nmr_spectrum_editor_info <- function(internal_id) {
  params <- list("internal_id" = internal_id)
  result <- generic_request(
    "query" = params[["internal_id"]],
    "endpoint" = "amos/get_nmr_spectrum_editor_info/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
