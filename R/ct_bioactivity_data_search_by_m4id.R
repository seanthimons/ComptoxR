#' Get data for a batch of M4IDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param m4id Level 4 model identifiers. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id_bulk(m4id = list("7826737", "7826738"))
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_m4id_bulk <- function(m4id) {
  m4id <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(m4id)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  if (base::missing(m4id)) {
    base::stop("Required m4id")
  }
  if (!base::missing(m4id)) {
    m4id <- base::tryCatch(
      .api_validation$body_value(m4id, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop("Invalid m4id: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(m4id)) m4id <- jsonlite::unbox(NA)
  }
  params <- base::list("m4id" = m4id)
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/bioactivity/data/search/by-m4id/",
      path_params = base::list(),
      query = base::list(),
      body = params[["m4id"]],
      response_policy = ".ct_tidy",
      server = list(url = "https://comptox.epa.gov/ctx-api"),
      server_resolver = list(name = ".ct_server_url", key = "ctx_burl"),
      auth = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      ))),
      batch = base::list(max_items = .batch_limit)
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["m4id"] <- base::list(chunk)
      send(params)
    },
    params[["m4id"]],
    .batch_limit,
    on_error = "drop"
  )
}

#' Get data by M4ID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param m4id m4id Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id(m4id = 7826737L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_m4id <- function(m4id) {
  m4id <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(m4id)
  if (base::is.null(m4id)) {
    base::stop("Required input: m4id")
  }
  .api_validation$parameter_values(
    base::list("m4id" = m4id),
    list(m4id = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(m4id = "path")
  )
  params <- base::list("m4id" = m4id)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/data/search/by-m4id/{m4id}",
      path_params = base::list("m4id" = params[["m4id"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_tidy",
      server = list(url = "https://comptox.epa.gov/ctx-api"),
      server_resolver = list(name = ".ct_server_url", key = "ctx_burl"),
      auth = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      )))
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["m4id"] <- base::list(chunk)
      send(params)
    },
    params[["m4id"]],
    1L,
    on_error = "drop"
  )
}
