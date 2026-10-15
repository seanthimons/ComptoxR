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
# Generated with specmill; do not edit by hand.
chemi_stdizer_records <- function(full = NULL, options = NULL, records = NULL) {
  params <- base::list("full" = full, "options" = options, "records" = records)
  result <- generic_chemi_request(
    "query" = params[["full"]],
    "endpoint" = "stdizer/records",
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list("options" = params[["options"]], "records" = params[["records"]])
      )
      if (base::length(.body)) .body else base::list()
    }),
    "tidy" = FALSE
  )
  result
}
