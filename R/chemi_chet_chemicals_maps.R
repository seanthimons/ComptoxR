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
  params <- base::list("chemid" = chemid)
  result <- generic_request(
    "endpoint" = "chemicals/maps",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("chemid" = params[["chemid"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
