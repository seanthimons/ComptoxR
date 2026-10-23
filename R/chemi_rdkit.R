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

#' Generate descriptors for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Chemical structures or resolvable identifiers
#' @param options Named list of additional dedicated RDKit options
#' @param type Fingerprint type
#' @param radius ECFP radius
#' @param bits Number of fingerprint bits
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_rdkit_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_rdkit_bulk <- function(
  chemicals,
  options = NULL,
  type = NULL,
  radius = NULL,
  bits = NULL,
  output = c("wide", "raw")
) {
  params <- base::list(
    "chemicals" = chemicals,
    "options" = options,
    "type" = type,
    "radius" = radius,
    "bits" = bits,
    "output" = output
  )
  state <- run_hook("chemi_rdkit_bulk", "pre_request", base::list(params = params))
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
        if (
          context$status >= 200L &&
            context$status < 300L &&
            grepl("^text/(csv|tab-separated-values|tsv)", state$request$content_type, ignore.case = TRUE)
        ) {
          observe_api_responses(list(response))
          value <- .ct_response_delimited(response, context, decode)
          return(if (!length(value)) list() else value)
        }
        context$endpoint <- state$request$endpoint
        .ct_chemi_result(response, context, decode, tidy = FALSE)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_rdkit_bulk", "post_response", state)
  result
}
