#' Get detailed data for a batch of DTXSIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox substance identifiers. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_details_search_bulk(dtxsid = list("DTXSID7020182", "DTXSID2021315"))
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_details_search_bulk <- function(dtxsid) {
  dtxsid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxsid)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  if (base::missing(dtxsid)) {
    base::stop("Required dtxsid")
  }
  if (!base::missing(dtxsid)) {
    dtxsid <- base::tryCatch(
      .api_validation$body_value(dtxsid, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop("Invalid dtxsid: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(dtxsid)) dtxsid <- jsonlite::unbox(NA)
  }
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/hazard/genetox/details/search/by-dtxsid/",
      path_params = base::list(),
      query = base::list(),
      body = params[["dtxsid"]],
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
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    .batch_limit,
    on_error = "drop",
    empty = .ct_empty_table
  )
}

#' Get detailed data by DTXSID with CCD projection
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @param projection projection
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_details_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_details_search <- function(dtxsid, projection = NULL) {
  dtxsid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxsid)
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "projection" = projection),
    list(dtxsid = list(type = "array", items = list(type = "string")), projection = list(type = "string")),
    .api_validation$body_value,
    c(dtxsid = "path", projection = "query")
  )
  params <- base::list("dtxsid" = dtxsid, "projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/genetox/details/search/by-dtxsid/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
      query = base::list("projection" = params[["projection"]]),
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
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
