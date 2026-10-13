#' Get data for a batch of DTXSID(s).
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param body Request body. Arrays longer than 100 items are sent in chunks of that size and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxval_search_bulk(body = list("DTXSID1024122", "DTXSID4020533"))
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxval_search_bulk <- function(body) {
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(body, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop('Invalid body: ', base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/hazard/toxval/search/by-dtxsid/",
      path_params = base::list(),
      query = base::list(),
      body = params[["body"]],
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
      batch = list(max_items = 100L)
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["body"] <- base::list(chunk)
      send(params)
    },
    params[["body"]],
    100L,
    on_error = "drop"
  )
}

#' Get data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxval_search(dtxsid = "DTXSID0021125")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxval_search <- function(dtxsid) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(dtxsid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/toxval/search/by-dtxsid/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
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
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = "drop"
  )
}
