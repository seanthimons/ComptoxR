#' Get MS-ready chemicals for a batch of DTXCIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxcid DSSTox compound identifiers. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_dtxcid_bulk(dtxcid = list("DTXCID30182", "DTXCID505"))
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_msready_search_by_dtxcid_bulk <- function(dtxcid) {
  dtxcid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxcid)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  if (base::missing(dtxcid)) {
    base::stop("Required dtxcid")
  }
  if (!base::missing(dtxcid)) {
    dtxcid <- base::tryCatch(
      .api_validation$body_value(dtxcid, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop("Invalid dtxcid: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(dtxcid)) dtxcid <- jsonlite::unbox(NA)
  }
  params <- base::list("dtxcid" = dtxcid)
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/chemical/msready/search/by-dtxcid/",
      path_params = base::list(),
      query = base::list(),
      body = params[["dtxcid"]],
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
      params["dtxcid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxcid"]],
    .batch_limit,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
