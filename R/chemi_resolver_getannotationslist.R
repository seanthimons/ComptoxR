#' Resolver Getannotationslist
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param name Required parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getannotationslist(name = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_getannotationslist <- function(name) {
  params <- base::list("name" = name)
  result <- generic_request(
    "endpoint" = "resolver/getannotationslist",
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
