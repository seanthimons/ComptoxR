#' Calculate RDKit fingerprints for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This wrapper resolves identifier-like inputs to SMILES before calling the
#' dedicated service. The raw `/api/rdkit` endpoint does not perform that
#' wrapper-level resolution.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param type Fingerprint type. Currently `ecfp`.
#' @param radius ECFP radius.
#' @param bits Number of fingerprint bits.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated one-row tibble or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_rdkit(smiles = "DTXSID7020182", bits = 1024)
#' }
chemi_rdkit <- function(
  smiles,
  type = NULL,
  radius = NULL,
  bits = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_rdkit",
    "transform",
    list(
      params = list(
        smiles = smiles,
        type = type,
        radius = radius,
        bits = bits,
        output = output
      )
    )
  )
  result
}

#' Calculate RDKit fingerprints for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Explicit engine arguments override duplicate values in `options`.
#'
#' @param chemicals Chemical structures or resolvable identifiers.
#' @param options Named list of additional dedicated RDKit options.
#' @param type Fingerprint type. Currently `ecfp`.
#' @param radius ECFP radius.
#' @param bits Number of fingerprint bits.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated tibble with one row per input or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_rdkit_bulk(c("DTXSID7020182", "CCO"), bits = 1024)
#' }
chemi_rdkit_bulk <- function(
  chemicals,
  options = NULL,
  type = NULL,
  radius = NULL,
  bits = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_rdkit_bulk",
    "transform",
    list(
      params = list(
        chemicals = chemicals,
        options = options,
        type = type,
        radius = radius,
        bits = bits,
        output = output
      )
    )
  )
  result
}
