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
#' @apiStage staging
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
  req_data <- run_hook(
    "chemi_mordred",
    "pre_request",
    list(
      params = list(
        smiles = smiles,
        headers = headers,
        inchi = inchi,
        output = output
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    result <- req_data$result
  } else {
    result <- generic_request(
      endpoint = req_data$request$endpoint,
      method = req_data$request$method,
      batch_limit = 0,
      server = req_data$request$server,
      auth = FALSE,
      tidy = FALSE,
      content_type = req_data$request$content_type,
      options = req_data$request$options
    )
  }

  post_data <- req_data
  post_data$result <- result
  result <- run_hook("chemi_mordred", "post_response", post_data)

  return(result)
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
#' @apiStage staging
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
  req_data <- run_hook(
    "chemi_mordred_bulk",
    "pre_request",
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
  if (isTRUE(req_data$skip_request)) {
    result <- req_data$result
  } else {
    result <- generic_chemi_request(
      endpoint = req_data$request$endpoint,
      server = req_data$request$server,
      auth = FALSE,
      tidy = FALSE,
      body = req_data$request$body,
      content_type = req_data$request$content_type
    )
  }

  post_data <- req_data
  post_data$result <- result
  result <- run_hook("chemi_mordred_bulk", "post_response", post_data)

  return(result)
}
