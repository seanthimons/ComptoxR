#' Padel
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param x2d Calculate two-dimensional descriptors (default: TRUE)
#' @param x3d Calculate three-dimensional descriptors (default: FALSE)
#' @param fp Calculate fingerprints (default: FALSE)
#' @param headers Request upstream descriptor headers (default: FALSE)
#' @param timeout Optional upstream calculation timeout
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_padel(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_padel <- function(
  smiles,
  x2d = TRUE,
  x3d = FALSE,
  fp = FALSE,
  headers = FALSE,
  timeout = NULL,
  output = c("wide", "raw")
) {
  params <- base::list(
    "smiles" = smiles,
    "x2d" = x2d,
    "x3d" = x3d,
    "fp" = fp,
    "headers" = headers,
    "timeout" = timeout,
    "output" = output
  )
  state <- run_hook("chemi_padel", "pre_request", base::list(params = params))
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
  result <- run_hook("chemi_padel", "post_response", state)
  result
}
