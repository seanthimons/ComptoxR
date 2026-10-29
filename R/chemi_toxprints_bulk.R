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
