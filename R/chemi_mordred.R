#' Generate descriptors for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param headers Request upstream descriptor headers
#' @param inchi Include InChI identifiers
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_mordred(smiles = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_mordred <- function(smiles, headers = NULL, inchi = NULL, output = c("wide", "raw")) {
  params <- list("smiles" = smiles, "headers" = headers, "inchi" = inchi, "output" = output)
  state <- run_hook("chemi_mordred", "pre_request", list(params = params))
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
  result <- run_hook("chemi_mordred", "post_response", state)
  result
}

#' Generate descriptors for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Chemical structures or resolvable identifiers
#' @param options Named list of additional dedicated Mordred options
#' @param headers Request descriptor headers
#' @param inchi Include InChI identifiers
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_mordred_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_mordred_bulk <- function(chemicals, options = NULL, headers = NULL, inchi = NULL, output = c("wide", "raw")) {
  params <- list("chemicals" = chemicals, "options" = options, "headers" = headers, "inchi" = inchi, "output" = output)
  state <- run_hook("chemi_mordred_bulk", "pre_request", list(params = params))
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
  result <- run_hook("chemi_mordred_bulk", "post_response", state)
  result
}
