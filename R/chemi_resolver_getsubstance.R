#' Resolver Getsubstance
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param name Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getsubstance(name = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_getsubstance <- function(name) {
  params <- list("name" = name)
  result <- generic_request(
    "endpoint" = "resolver/getsubstance",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("name" = params[["name"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
