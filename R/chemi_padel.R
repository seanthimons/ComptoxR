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
#' @apiStage public
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
  req_data <- run_hook(
    "chemi_padel",
    "pre_request",
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
  result <- run_hook("chemi_padel", "post_response", post_data)

  return(result)
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
#' @apiStage public
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
  req_data <- run_hook(
    "chemi_padel_bulk",
    "pre_request",
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
  result <- run_hook("chemi_padel_bulk", "post_response", post_data)

  return(result)
}
