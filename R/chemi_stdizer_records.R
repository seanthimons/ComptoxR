#' Stdizer Records
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param full Optional parameter
#' @param options Optional parameter
#' @param records Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_records(full = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_stdizer_records <- function(full = NULL, options = NULL, records = NULL) {
  params <- list("full" = full, "options" = options, "records" = records)
  result <- generic_chemi_request(
    "query" = params[["full"]],
    "endpoint" = "stdizer/records",
    "options" = local({
      .body <- Filter(Negate(is.null), list("options" = list(), "records" = params[["records"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
