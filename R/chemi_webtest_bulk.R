#' Webtest
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Chemical structures or resolvable identifiers
#' @param chemIdType Input identifier type. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param headers Request descriptor headers
#' @param format Deprecated; responses are always JSON.
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_webtest_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_webtest_bulk <- function(
  query,
  chemIdType = "AnyId",
  headers = FALSE,
  format = "JSON",
  output = c("wide", "raw")
) {
  params <- base::list(
    "query" = query,
    "chemIdType" = chemIdType,
    "headers" = headers,
    "format" = format,
    "output" = output
  )
  state <- run_hook("chemi_webtest_bulk", "pre_request", base::list(params = params))
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- .ct_request(
      "method" = "POST",
      "path" = state[["request"]][["endpoint"]],
      "path_params" = structure(list(), names = character(0)),
      "query" = structure(list(), names = character(0)),
      "body" = state[["request"]][["body"]],
      "headers" = base::list("Accept" = state[["request"]][["content_type"]]),
      "server" = base::list("url" = state[["request"]][["server"]]),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        if (context$status >= 400L) {
          decode()
        }
        context$endpoint <- state$request$endpoint
        .ct_chemi_result(response, context, decode, tidy = FALSE)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_webtest_bulk", "post_response", state)
  result
}
