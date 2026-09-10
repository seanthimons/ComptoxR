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
  params <- list(
    "smiles" = smiles,
    "x2d" = x2d,
    "x3d" = x3d,
    "fp" = fp,
    "headers" = headers,
    "timeout" = timeout,
    "output" = output
  )
  state <- run_hook("chemi_padel", "pre_request", list(params = params))
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
  result <- run_hook("chemi_padel", "post_response", state)
  result
}

#' Padel
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Chemical structures or resolvable identifiers
#' @param x2d Calculate two-dimensional descriptors
#' @param x3d Calculate three-dimensional descriptors
#' @param fp Calculate fingerprints
#' @param headers Request descriptor headers
#' @param timeout Optional upstream calculation timeout
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_padel_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_padel_bulk <- function(
  query,
  x2d = TRUE,
  x3d = FALSE,
  fp = FALSE,
  headers = FALSE,
  timeout = NULL,
  output = c("wide", "raw")
) {
  params <- list(
    "query" = query,
    "x2d" = x2d,
    "x3d" = x3d,
    "fp" = fp,
    "headers" = headers,
    "timeout" = timeout,
    "output" = output
  )
  state <- run_hook("chemi_padel_bulk", "pre_request", list(params = params))
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
  result <- run_hook("chemi_padel_bulk", "post_response", state)
  result
}
