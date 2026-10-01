#' Fetch aliases for a chemical
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_alias(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_alias <- function(dtxsid = NULL) {
  params <- base::list("dtxsid" = dtxsid)
  result <- generic_request(
    "endpoint" = "chemicals/alias",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("dtxsid" = params[["dtxsid"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
