#' Calculate WebTEST descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This wrapper resolves identifier-like inputs to SMILES before calling the
#' dedicated service. The raw `/api/webtest` endpoint does not perform that
#' wrapper-level resolution.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param headers Request upstream descriptor headers.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated one-row tibble or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest(smiles = "DTXSID7020182")
#' }
chemi_webtest <- function(
  smiles,
  headers = FALSE,
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_webtest",
    "transform",
    list(
      params = list(
        smiles = smiles,
        headers = headers,
        output = output
      )
    )
  )
  result
}

#' Calculate WebTEST descriptors for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Chemical structures or resolvable identifiers.
#' @param chemIdType Identifier type used for wrapper-level input resolution.
#' @param headers Request upstream descriptor headers.
#' @param format Response format: `JSON`, `CSV`, or `TSV`.
#' @param output `wide` for a validated tibble or `raw` for the payload with
#'   provenance attributes.
#' @return A validated tibble with one row per input or raw payload.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_bulk(c("DTXSID7020182", "CCO"))
#' }
chemi_webtest_bulk <- function(
  query,
  chemIdType = "AnyId",
  headers = FALSE,
  format = "JSON",
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_webtest_bulk",
    "transform",
    list(
      params = list(
        query = query,
        chemIdType = chemIdType,
        headers = headers,
        format = format,
        output = output
      )
    )
  )
  result
}
