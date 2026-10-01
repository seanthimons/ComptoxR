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
  params <- base::list("name" = name)
  result <- generic_request(
    "endpoint" = "resolver/getsubstance",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("name" = params[["name"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
