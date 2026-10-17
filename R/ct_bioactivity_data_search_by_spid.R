#' Get data for a batch of SPIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param spid Sample identifiers. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid_bulk(spid = list("EPAPLT0232A03", "EPAPLT0232A04"))
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_spid_bulk <- function(spid) {
  spid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(spid)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  if (base::missing(spid)) {
    base::stop("Required spid")
  }
  if (!base::missing(spid)) {
    spid <- base::tryCatch(
      .api_validation$body_value(spid, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop("Invalid spid: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(spid)) spid <- jsonlite::unbox(NA)
  }
  params <- base::list("spid" = spid)
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/bioactivity/data/search/by-spid/",
      path_params = base::list(),
      query = base::list(),
      body = params[["spid"]],
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
      params["spid"] <- base::list(chunk)
      send(params)
    },
    params[["spid"]],
    .batch_limit,
    on_error = "drop"
  )
}

#' Get data by SPID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param spid spid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid(spid = "EPAPLT0232A03")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_by_spid <- function(spid) {
  spid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(spid)
  if (base::is.null(spid)) {
    base::stop("Required input: spid")
  }
  .api_validation$parameter_values(
    base::list("spid" = spid),
    list(spid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(spid = "path")
  )
  params <- base::list("spid" = spid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/data/search/by-spid/{spid}",
      path_params = base::list("spid" = params[["spid"]]),
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
      params["spid"] <- base::list(chunk)
      send(params)
    },
    params[["spid"]],
    1L,
    on_error = "drop"
  )
}
