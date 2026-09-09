#' Webtest
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param headers Request upstream descriptor headers (default: FALSE)
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_webtest(smiles = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_webtest <- function(smiles, headers = FALSE, output = c("wide", "raw")) {
  params <- list("smiles" = smiles, "headers" = headers, "output" = output)
  state <- run_hook("chemi_webtest", "pre_request", list(params = params))
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  if (isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- generic_request(
      "endpoint" = state[["request"]][["endpoint"]],
      "method" = state[["request"]][["method"]],
      "batch_limit" = 0,
      "server" = state[["request"]][["server"]],
      "auth" = FALSE,
      "tidy" = FALSE,
      "content_type" = state[["request"]][["content_type"]],
      "options" = state[["request"]][["options"]]
    )
  }
  state["result"] <- list(result)
  result <- run_hook("chemi_webtest", "post_response", state)
  result
}

#' Webtest
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Chemical structures or resolvable identifiers
#' @param chemIdType Input identifier type. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param headers Request descriptor headers
#' @param format Response format: JSON, CSV, or TSV. Options: JSON, CSV, TSV (default: JSON)
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_webtest_bulk(query = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_webtest_bulk <- function(
  query,
  chemIdType = "AnyId",
  headers = FALSE,
  format = "JSON",
  output = c("wide", "raw")
) {
  params <- list("query" = query, "chemIdType" = chemIdType, "headers" = headers, "format" = format, "output" = output)
  state <- run_hook("chemi_webtest_bulk", "pre_request", list(params = params))
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  if (isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- generic_chemi_request(
      "endpoint" = state[["request"]][["endpoint"]],
      "server" = state[["request"]][["server"]],
      "auth" = FALSE,
      "tidy" = FALSE,
      "body" = state[["request"]][["body"]],
      "content_type" = state[["request"]][["content_type"]]
    )
  }
  state["result"] <- list(result)
  result <- run_hook("chemi_webtest_bulk", "post_response", state)
  result
}
