#' Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Calculates ToxPrint descriptors for one structure and preserves the API response envelope. Use chemi_toxprints_bulk for a row-per-chemical table.
#' @param smiles One SMILES string. DTXSID acceptance depends on the service deployment.
#' @param headers Include descriptor names in the response; defaults to FALSE.
#' @param profile Optional profile name; NULL uses the service default.
#' @return A list containing the API response envelope with service metadata, chemicals and optional descriptor headers.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints(smiles = "CCO")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints <- function(smiles, headers = FALSE, profile = NULL) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "headers" = headers, "profile" = profile),
    list(
      smiles = list(type = "string"),
      headers = list(default = FALSE, type = "boolean"),
      profile = list(type = "string")
    ),
    .api_validation$body_value,
    c(smiles = "query", headers = "query", profile = "query")
  )
  params <- base::list("smiles" = smiles, "headers" = headers, "profile" = profile)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["headers"]]) && base::any(!base::nzchar(params[["headers"]]))) {
    base::stop("Empty query parameter: headers")
  }
  if (base::is.character(params[["profile"]]) && base::any(!base::nzchar(params[["profile"]]))) {
    base::stop("Empty query parameter: profile")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/toxprints",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]], "headers" = params[["headers"]], "profile" = params[["profile"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    parameter_serialization = list(list(
      name = "headers",
      location = "query",
      schema = list(default = FALSE, type = "boolean"),
      style = "form",
      explode = TRUE,
      collection_format = NULL,
      required = FALSE
    ))
  )
  result
}

#' Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Calculates ToxPrint descriptors using the Cheminformatics service without CTX authentication. Inputs are cleaned and split by batch_limit, default 100.
#' @param query Character vector of chemical structure strings. SMILES work in production and development; DTXSID support depends on the service deployment.
#' @return One row per chemical, with descriptor vectors and service metadata retained in descriptors and info list-columns.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_bulk(query = "CCO")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_bulk <- function(query) {
  query <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(query)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  params <- base::list("query" = query)
  send <- function(params) {
    result <- .ct_request(
      "method" = "POST",
      "path" = "/api/toxprints",
      "path_params" = structure(list(), names = character(0)),
      "query" = structure(list(), names = character(0)),
      "body" = .api_validation$body_value(
        base::list(chemicals = base::as.list(params$query)),
        structure(
          list(
            properties = list(
              chemicals = list(items = list(type = "string"), type = "array"),
              options = structure(
                list(properties = list(headers = list(type = "boolean")), type = "object"),
                specmill_id = "#/components/schemas/Options"
              ),
              profile = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/ToxprintsRequest"
        )
      ),
      "headers" = list(Accept = "application/json"),
      "server" = list(url = "https://hcd.rtpnc.epa.gov"),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        observe_api_responses(list(response))
        body <- decode()
        records <- .ct_request_records(body, collection = "chemicals", null_to_na = TRUE)
        records <- lapply(records, function(record) {
          record$info <- body$info
          record
        })
        .ct_request_table(records, build = function(records, ...) {
          purrr::list_rbind(lapply(records, function(record) {
            record$descriptors <- list(unlist(record$descriptors, use.names = FALSE))
            record$info <- list(record$info)
            tibble::as_tibble(record)
          }))
        })
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
    result
  }
  result <- .ct_request_each(
    function(chunk) {
      params["query"] <- base::list(chunk)
      send(params)
    },
    params[["query"]],
    .batch_limit,
    on_error = list(single = "stop", multiple = "drop"),
    empty = .ct_empty_table,
    warning = FALSE
  )
  base::attr(result, "failed") <- NULL
  result
}
