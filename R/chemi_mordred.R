#' Calculate Mordred descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Production calls use the staging dedicated Mordred deployment because the
#' production dedicated deployment is unavailable.
#'
#' This wrapper resolves identifier-like inputs to SMILES before calling the
#' dedicated service. The raw `/api/mordred` endpoint does not perform that
#' wrapper-level resolution.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param headers Request upstream descriptor headers.
#' @param inchi Include InChI identifiers.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated one-row tibble or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_mordred(smiles = "DTXSID7020182")
#' }
chemi_mordred <- function(
  smiles,
  headers = NULL,
  inchi = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_mordred",
    "transform",
    list(
      params = list(
        smiles = smiles,
        headers = headers,
        inchi = inchi,
        output = output
      )
    )
  )
  result
}

#' Calculate Mordred descriptors for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Explicit `headers` and `inchi` arguments override duplicate values in
#' `options`.
#'
#' @param chemicals Chemical structures or resolvable identifiers.
#' @param options Named list of additional dedicated Mordred options.
#' @param headers Request upstream descriptor headers.
#' @param inchi Include InChI identifiers.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated tibble with one row per input or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_mordred_bulk(c("DTXSID7020182", "CCO"))
#' }
chemi_mordred_bulk <- function(
  chemicals,
  options = NULL,
  headers = NULL,
  inchi = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_mordred_bulk",
    "transform",
    list(
      params = list(
        chemicals = chemicals,
        options = options,
        headers = headers,
        inchi = inchi,
        output = output
      )
    )
  )
  result
}
