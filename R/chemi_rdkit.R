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
# Generated with apipak; do not edit by hand.
chemi_rdkit <- function(smiles, type = NULL, radius = NULL, bits = NULL, output = c("wide", "raw")) {
  params <- list("smiles" = smiles, "type" = type, "radius" = radius, "bits" = bits, "output" = output)
  state <- run_hook("chemi_rdkit", "pre_request", list(params = params))
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
# Generated with apipak; do not edit by hand.
chemi_rdkit_bulk <- function(
  chemicals,
  options = NULL,
  type = NULL,
  radius = NULL,
  bits = NULL,
  output = c("wide", "raw")
) {
  params <- list(
    "chemicals" = chemicals,
    "options" = options,
    "type" = type,
    "radius" = radius,
    "bits" = bits,
    "output" = output
  )
  state <- run_hook("chemi_rdkit_bulk", "pre_request", list(params = params))
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
  result <- run_hook("chemi_rdkit_bulk", "post_response", state)
  result
}
