#' Get data for a batch of AEIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid Assay endpoint identifiers. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_aeid_bulk(aeid = list("3032", "3033"))
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_aeid_bulk <- function(aeid) {
  aeid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(aeid)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  if (base::missing(aeid)) {
    base::stop("Required aeid")
  }
  if (!base::missing(aeid)) {
    aeid <- base::tryCatch(
      .api_validation$body_value(aeid, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop("Invalid aeid: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(aeid)) aeid <- jsonlite::unbox(NA)
  }
  params <- base::list("aeid" = aeid)
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/bioactivity/data/search/by-aeid/",
      path_params = base::list(),
      query = base::list(),
      body = params[["aeid"]],
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
      params["aeid"] <- base::list(chunk)
      send(params)
    },
    params[["aeid"]],
    .batch_limit,
    on_error = "drop",
    empty = .ct_empty_table
  )
}

#' Get data by AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid aeid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_aeid(aeid = 3032L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_aeid <- function(aeid) {
  aeid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(aeid)
  if (base::is.null(aeid)) {
    base::stop("Required input: aeid")
  }
  .api_validation$parameter_values(
    base::list("aeid" = aeid),
    list(aeid = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(aeid = "path")
  )
  params <- base::list("aeid" = aeid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/data/search/by-aeid/{aeid}",
      path_params = base::list("aeid" = params[["aeid"]]),
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
      params["aeid"] <- base::list(chunk)
      send(params)
    },
    params[["aeid"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
