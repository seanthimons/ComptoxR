#' Get summary data for a batch of DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox substance identifiers. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_genetox_summary_search_by_dtxsid_bulk(dtxsid = list("DTXSID7020182", "DTXSID2021315"))
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_genetox_summary_search_by_dtxsid_bulk <- function(dtxsid) {
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
      path = "/hazard/genetox/summary/search/by-dtxsid/",
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
