#' Map list for a chemical
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_maps(chemid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_maps <- function(chemid = NULL) {
  params <- list("chemid" = chemid)
  result <- generic_request(
    "endpoint" = "chemicals/maps",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("chemid" = params[["chemid"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
