#' Resolver lookupCASRN
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_lookupCASRN(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_lookupCASRN <- function(query) {
  if (base::is.null(query)) {
    base::stop("Required input: query")
  }
  .api_validation$parameter_values(
    base::list("query" = query),
    list(query = list(type = "string", description = "Required parameter")),
    .api_validation$body_value,
    c(query = "query")
  )
  params <- base::list("query" = query)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  result <- generic_request(
    "endpoint" = "resolver/lookupCASRN",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("query" = params[["query"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
