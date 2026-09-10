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
  params <- list("content" = content, "type" = type)
  result <- generic_chemi_request(
    "query" = params[["content"]],
    "endpoint" = "services/convert",
    "options" = local({
      .body <- Filter(Negate(is.null), list("type" = params[["type"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
