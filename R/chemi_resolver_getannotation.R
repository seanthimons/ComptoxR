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
# Generated with apipak; do not edit by hand.
chemi_resolver_getannotation <- function(name, heading) {
  params <- list("name" = name, "heading" = heading)
  result <- generic_request(
    "endpoint" = "resolver/getannotation",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("name" = params[["name"]], "heading" = params[["heading"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
