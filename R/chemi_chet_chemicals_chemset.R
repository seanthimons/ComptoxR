#' List chemicals by library
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param setid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_chemset(setid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_chemset <- function(setid = NULL) {
  params <- list("setid" = setid)
  result <- generic_request(
    "endpoint" = "chemicals/chemset",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("setid" = params[["setid"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
