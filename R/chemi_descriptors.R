#' Descriptors
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param type Descriptor engine: padel, rdkit, mordred, or webtest
#' @param headers Request descriptor headers.
#' @param format Deprecated; responses are always JSON.
#' @param timeout Optional upstream calculation timeout.
#' @param output Output contract: validated wide tibble or raw payload.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_descriptors(smiles = "CCO", type = "rdkit")
#' }
# Generated with specmill; do not edit by hand.
chemi_descriptors <- function(
  smiles,
  type,
  headers = FALSE,
  format = "JSON",
  timeout = NULL,
  output = c("wide", "raw")
) {
  params <- base::list(
    "smiles" = smiles,
    "type" = type,
    "headers" = headers,
    "format" = format,
    "timeout" = timeout,
    "output" = output
  )
  state <- run_hook("chemi_descriptors", "pre_request", base::list(params = params))
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- .ct_request(
      "method" = "GET",
      "path" = state[["request"]][["endpoint"]],
      "path_params" = structure(list(), names = character(0)),
      "query" = state[["request"]][["options"]],
      "body" = NULL,
      "headers" = base::list("Accept" = state[["request"]][["content_type"]]),
      "server" = base::list("url" = state[["request"]][["server"]]),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        .ct_static_json_result(response, context, decode, state$request$endpoint)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_descriptors", "post_response", state)
  result
}
