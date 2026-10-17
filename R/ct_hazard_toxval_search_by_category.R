#' Get all data by dtxsid and category
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @param category category
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxval_search_by_category(dtxsid = "DTXSID0021125", category = "Dose Response Summary Value")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxval_search_by_category <- function(dtxsid, category) {
  dtxsid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxsid)
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  if (base::is.null(category)) {
    base::stop("Required input: category")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "category" = category),
    list(dtxsid = list(type = "array", items = list(type = "string")), category = list(type = "string")),
    .api_validation$body_value,
    c(dtxsid = "path", category = "query")
  )
  params <- base::list("dtxsid" = dtxsid, "category" = category)
  if (base::is.character(params[["category"]]) && base::any(!base::nzchar(params[["category"]]))) {
    base::stop("Empty query parameter: category")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/toxval/search/by-category/{dtxsid}",
      path_params = base::list("dtxsid" = params[["dtxsid"]]),
      query = base::list("category" = params[["category"]]),
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
