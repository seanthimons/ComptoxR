#' Returns an IR spectrum by database ID.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_id Unique ID of the IR spectrum of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_ir_spectrum(internal_id = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_get_ir_spectrum <- function(internal_id) {
  params <- list("internal_id" = internal_id)
  result <- generic_request(
    "query" = params[["internal_id"]],
    "endpoint" = "amos/get_ir_spectrum/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
