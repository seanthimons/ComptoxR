#' Returns the top four levels of a ClassyFire classification of a given substance.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_classification_for_dtxsid(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_classification_for_dtxsid <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "amos/get_classification_for_dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
