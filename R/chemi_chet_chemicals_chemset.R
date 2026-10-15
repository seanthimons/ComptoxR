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
  params <- base::list("setid" = setid)
  result <- generic_request(
    "endpoint" = "chemicals/chemset",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("setid" = params[["setid"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
