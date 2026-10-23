#' Services Convert
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param content Optional parameter
#' @param type Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_services_convert(content = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_services_convert <- function(content = NULL, type = NULL) {
  params <- base::list("content" = content, "type" = type)
  result <- generic_chemi_request(
    "query" = params[["content"]],
    "endpoint" = "services/convert",
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("type" = params[["type"]]))
      if (base::length(.body)) .body else base::list()
    }),
    "tidy" = FALSE
  )
  result
}
