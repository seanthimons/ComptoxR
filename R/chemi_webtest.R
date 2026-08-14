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
#' @apiStage public
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
  req_data <- run_hook(
    "chemi_webtest",
    "pre_request",
    list(
      params = list(
        smiles = smiles,
        headers = headers,
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
  result <- run_hook("chemi_webtest", "post_response", post_data)

  return(result)
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
#' @apiStage public
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
  req_data <- run_hook(
    "chemi_webtest_bulk",
    "pre_request",
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
  result <- run_hook("chemi_webtest_bulk", "post_response", post_data)

  return(result)
}
