#' Get chemicals for a batch of exact values
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of values to search for Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return A tibble with search results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_equal_bulk(query = c("DTXSID7020182", "DTXSID9020112"))
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_equal_bulk <- function(query) {
  query <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(query)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 1000L, 200L)
  if (base::missing(query)) {
    base::stop("Required query")
  }
  if (!base::missing(query)) {
    .api_validation$text_input(query)
  }
  params <- base::list("query" = query)
  send <- function(params) {
    .text_body <- params[["query"]]
    if (!base::is.null(.text_body)) {
      .text_body <- .api_validation$text_value(.text_body, "lines", .batch_limit)
      .text_body <- base::tryCatch(.api_validation$body_value(.text_body, list(type = "string")), error = function(e) {
        base::stop("Invalid .text_body: ", base::conditionMessage(e), call. = FALSE)
      })
    }
    result <- .ct_request(
      "method" = "POST",
      "path" = "/chemical/search/equal/",
      "path_params" = list(),
      "query" = list(),
      "body" = .text_body,
      "headers" = list(Accept = "application/json"),
      "body_media" = "text/plain",
      "server" = list(url = "https://comptox.epa.gov/ctx-api"),
      "server_resolver" = list(name = ".ct_server_url", key = "ctx_burl"),
      "auth" = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      ))),
      "response_policy" = function(response, context, decode) {
        context$query <- params[["query"]]
        .ct_http_policy_ct_chemical_search_equal_bulk(response, context, decode)
      }
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
    warning = base::get(
      ".ct_batch_http_warning",
      envir = base::parent.env(base::environment()),
      mode = "function",
      inherits = FALSE
    )
  )
  base::attr(result, "failed") <- NULL
  result
}
