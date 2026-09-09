#' Generate a standalone OPERA calculation report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox substance identifier
#' @param modelId Dashboard model ID for the OPERA endpoint
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_opera_report(dtxsid = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_opera_report <- function(dtxsid, modelId) {
  params <- list("dtxsid" = dtxsid, "modelId" = modelId)
  result <- generic_request(
    "endpoint" = "opera/report",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("dtxsid" = params[["dtxsid"]], "modelId" = params[["modelId"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
