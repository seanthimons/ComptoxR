#' Returns an IR spectrum by database ID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the IR spectrum of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_ir_spectrum(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_ir_spectrum <- function(internal_id) {
  generic_request(
    query = internal_id,
    endpoint = "amos/get_ir_spectrum/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


