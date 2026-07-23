#' Calculate PaDEL descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This wrapper resolves identifier-like inputs to SMILES before calling the
#' dedicated service. The raw `/api/padel` endpoint does not perform that
#' wrapper-level resolution.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param x2d Calculate two-dimensional descriptors.
#' @param x3d Calculate three-dimensional descriptors.
#' @param fp Calculate fingerprints.
#' @param headers Request upstream descriptor headers.
#' @param timeout Optional upstream calculation timeout.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated one-row tibble or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel(smiles = "DTXSID7020182")
#' }
chemi_padel <- function(
  smiles,
  x2d = TRUE,
  x3d = FALSE,
  fp = FALSE,
  headers = FALSE,
  timeout = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_padel",
    "transform",
    list(
      params = list(
        smiles = smiles,
        x2d = x2d,
        x3d = x3d,
        fp = fp,
        headers = headers,
        timeout = timeout,
        output = output
      )
    )
  )
  result
}

#' Calculate PaDEL descriptors for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Chemical structures or resolvable identifiers.
#' @param x2d Calculate two-dimensional descriptors.
#' @param x3d Calculate three-dimensional descriptors.
#' @param fp Calculate fingerprints.
#' @param headers Request upstream descriptor headers.
#' @param timeout Optional upstream calculation timeout.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated tibble with one row per input or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel_bulk(query = c("DTXSID7020182", "CCO"))
#' }
chemi_padel_bulk <- function(
  query,
  x2d = TRUE,
  x3d = FALSE,
  fp = FALSE,
  headers = FALSE,
  timeout = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_padel_bulk",
    "transform",
    list(
      params = list(
        query = query,
        x2d = x2d,
        x3d = x3d,
        fp = fp,
        headers = headers,
        timeout = timeout,
        output = output
      )
    )
  )
  result
}
