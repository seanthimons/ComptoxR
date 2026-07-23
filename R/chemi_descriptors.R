#' Calculate descriptors with the aggregate descriptor service
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Identifier-like inputs (DTXSID, DTXCID, and CASRN) are resolved to SMILES
#' before the request. Raw aggregate endpoints do not perform this wrapper-level
#' resolution.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param type Descriptor engine: `padel`, `rdkit`, `mordred`, or `webtest`.
#' @param headers Request upstream descriptor headers. Wide output always requests
#'   or deterministically generates headers.
#' @param format Response format: `JSON`, `CSV`, or `TSV`.
#' @param timeout Optional upstream calculation timeout.
#' @param output Output contract: `wide` returns a validated tibble; `raw`
#'   returns the unformatted payload with provenance attributes.
#' @return A validated one-row tibble or a raw payload with provenance.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors(smiles = "DTXSID7020182", type = "padel")
#' }
chemi_descriptors <- function(
  smiles,
  type,
  headers = FALSE,
  format = "JSON",
  timeout = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_descriptors",
    "transform",
    list(
      params = list(
        smiles = smiles,
        type = type,
        headers = headers,
        format = format,
        timeout = timeout,
        output = output
      )
    )
  )
  result
}

#' Calculate descriptors for multiple chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Every input position is represented in wide output, including duplicates,
#' missing inputs, unresolved identifiers, and failed structures.
#'
#' @param query Chemical identifiers or structures.
#' @param type Descriptor engine: `padel`, `rdkit`, `mordred`, or `webtest`.
#' @param chemIdType Input identifier type accepted by the aggregate service.
#' @param headers Request upstream descriptor headers. Wide output always requests
#'   or deterministically generates headers.
#' @param format Response format: `JSON`, `CSV`, or `TSV`.
#' @param timeout Optional upstream calculation timeout.
#' @param output Output contract: `wide` returns a validated tibble; `raw`
#'   returns the unformatted payload with provenance attributes.
#' @return A validated tibble with one row per input or a raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors_bulk(
#'   query = c("DTXSID7020182", "CCO"),
#'   type = "padel"
#' )
#' }
chemi_descriptors_bulk <- function(
  query,
  type,
  chemIdType = "AnyId",
  headers = FALSE,
  format = "JSON",
  timeout = NULL,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_descriptors_bulk",
    "transform",
    list(
      params = list(
        query = query,
        type = type,
        chemIdType = chemIdType,
        headers = headers,
        format = format,
        timeout = timeout,
        output = output
      )
    )
  )
  result
}
