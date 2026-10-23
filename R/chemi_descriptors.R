#' Descriptors
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param type Descriptor engine: padel, rdkit, mordred, or webtest
#' @param headers Request descriptor headers.
#' @param format Response format: JSON, CSV or TSV.
#' @param timeout Optional upstream calculation timeout.
#' @param output Output contract: validated wide tibble or raw payload.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_descriptors(smiles = "CCO", type = "rdkit")
#' }
# Generated with specmill; do not edit by hand.
chemi_descriptors <- function(
  smiles,
  type,
  headers = FALSE,
  format = "JSON",
  timeout = NULL,
  output = c("wide", "raw")
) {
  params <- base::list(
    "smiles" = smiles,
    "type" = type,
    "headers" = headers,
    "format" = format,
    "timeout" = timeout,
    "output" = output
  )
  state <- run_hook("chemi_descriptors", "pre_request", base::list(params = params))
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- .ct_request(
      "method" = "GET",
      "path" = state[["request"]][["endpoint"]],
      "path_params" = structure(list(), names = character(0)),
      "query" = state[["request"]][["options"]],
      "body" = NULL,
      "headers" = base::list("Accept" = state[["request"]][["content_type"]]),
      "server" = base::list("url" = state[["request"]][["server"]]),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        if (context$status >= 400L) {
          decode()
        }
        if (grepl("^text/(csv|tab-separated-values|tsv)", state$request$content_type, ignore.case = TRUE)) {
          observe_api_responses(list(response))
          return(
            if (!startsWith(tolower(state$request$content_type), context$media)) {
              parse_delimited_response(httr2::resp_body_string(response), state$request$content_type)
            } else {
              .ct_response_delimited(response, context, decode)
            }
          )
        }
        .ct_static_json_result(response, context, decode, state$request$endpoint)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_descriptors", "post_response", state)
  result
}

#' Descriptors
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Chemical identifiers or structures
#' @param type Descriptor engine: padel, rdkit, mordred, or webtest
#' @param chemIdType Input identifier type: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1 or AnyId.
#' @param headers Request descriptor headers.
#' @param format Response format: JSON, CSV or TSV.
#' @param timeout Optional upstream calculation timeout.
#' @param output Output contract: validated wide tibble or raw payload.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_descriptors_bulk(query = "CCO", type = "rdkit")
#' }
# Generated with specmill; do not edit by hand.
chemi_descriptors_bulk <- function(
  query,
  type,
  chemIdType = "AnyId",
  headers = FALSE,
  format = "JSON",
  timeout = NULL,
  output = c("wide", "raw")
) {
  params <- base::list(
    "query" = query,
    "type" = type,
    "chemIdType" = chemIdType,
    "headers" = headers,
    "format" = format,
    "timeout" = timeout,
    "output" = output
  )
  state <- run_hook("chemi_descriptors_bulk", "pre_request", base::list(params = params))
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- .ct_request(
      "method" = "POST",
      "path" = state[["request"]][["endpoint"]],
      "path_params" = structure(list(), names = character(0)),
      "query" = structure(list(), names = character(0)),
      "body" = state[["request"]][["body"]],
      "headers" = base::list("Accept" = state[["request"]][["content_type"]]),
      "server" = base::list("url" = state[["request"]][["server"]]),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        if (context$status >= 400L) {
          decode()
        }
        if (
          context$status >= 200L &&
            context$status < 300L &&
            grepl("^text/(csv|tab-separated-values|tsv)", state$request$content_type, ignore.case = TRUE)
        ) {
          observe_api_responses(list(response))
          value <- .ct_response_delimited(response, context, decode)
          return(if (!length(value)) list() else value)
        }
        context$endpoint <- state$request$endpoint
        .ct_chemi_result(response, context, decode, tidy = FALSE)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_descriptors_bulk", "post_response", state)
  result
}
