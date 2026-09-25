#' Resolver Getannotation
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param name Required parameter
#' @param heading Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getannotation(name = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_getannotation <- function(name, heading) {
  params <- base::list("name" = name, "heading" = heading)
  result <- generic_request(
    "endpoint" = "resolver/getannotation",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list("name" = params[["name"]], "heading" = params[["heading"]])
      )
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
