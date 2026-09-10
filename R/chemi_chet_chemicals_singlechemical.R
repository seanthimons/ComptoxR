#' Fetch a single chemical
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
#' chemi_chet_chemicals_singlechemical(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_singlechemical <- function(dtxsid = NULL) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "endpoint" = "chemicals/singlechemical",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("dtxsid" = params[["dtxsid"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
