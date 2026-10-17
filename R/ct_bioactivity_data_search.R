#' Get bioactivity data for a batch of DTXSIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox substance identifiers. Arrays longer than 100 items are sent in chunks of that size and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_bulk(dtxsid = list("DTXSID7020182", "DTXSID2021315"))
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_data_search_bulk <- function(dtxsid) {
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
      path = "/bioactivity/data/search/by-dtxsid/",
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
      batch = list(max_items = 100L)
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    100L,
    on_error = "drop"
  )
}
