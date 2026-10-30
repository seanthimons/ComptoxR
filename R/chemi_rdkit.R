#' Generate descriptors for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param type Fingerprint type
#' @param radius ECFP radius
#' @param bits Number of fingerprint bits
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_rdkit(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_rdkit <- function(smiles, type = NULL, radius = NULL, bits = NULL, output = c("wide", "raw")) {
  params <- base::list("smiles" = smiles, "type" = type, "radius" = radius, "bits" = bits, "output" = output)
  state <- run_hook("chemi_rdkit", "pre_request", base::list(params = params))
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
  result <- run_hook("chemi_rdkit", "post_response", state)
  result
}
