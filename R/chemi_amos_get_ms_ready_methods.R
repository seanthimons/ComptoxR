#' Retrieves a list of methods that contain the MS-Ready forms of a given substance but not the substance itself.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param inchikey InChIKey to search by.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_ms_ready_methods(inchikey = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_ms_ready_methods <- function(inchikey) {
  params <- list("inchikey" = inchikey)
  result <- generic_request(
    "query" = params[["inchikey"]],
    "endpoint" = "amos/get_ms_ready_methods/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
