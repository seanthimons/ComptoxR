#' Get chemical details in bulk
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param projection Projection options for chemical details APIs
#' @param query Request body. Inputs are sent in chunks using the configured call-time item limit and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_bulk(query = list("DTXSID7020182", "DTXSID9020112"))
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_detail_search_bulk <- function(query, projection = "chemicaldetailall") {
  query <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(query)
  .batch_limit <- .api_validation$batch_limit("batch_limit", 100L, NULL)
  .api_validation$parameter_values(
    base::list("projection" = projection),
    list(
      projection = list(
        description = "Projection options for chemical details APIs ",
        enum = list(
          "chemicaldetailstandard",
          "chemicalidentifier",
          "chemicalstructure",
          "ntatoolkit",
          "ccdchemicaldetails",
          "ccdassaydetails",
          "chemicaldetailall",
          "compact"
        ),
        type = "string",
        default = "chemicaldetailall"
      )
    ),
    .api_validation$body_value,
    c(projection = "query")
  )
  if (base::missing(query)) {
    base::stop("Required query")
  }
  if (!base::missing(query)) {
    query <- base::tryCatch(
      .api_validation$body_value(query, list(items = list(type = "string"), type = "array")),
      error = function(e) base::stop("Invalid query: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(query)) query <- jsonlite::unbox(NA)
  }
  params <- base::list("projection" = projection, "query" = query)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "POST",
      path = "/chemical/detail/search/by-dtxsid/",
      path_params = base::list(),
      query = base::list("projection" = params[["projection"]]),
      body = params[["query"]],
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
      params["query"] <- base::list(chunk)
      send(params)
    },
    params[["query"]],
    .batch_limit,
    on_error = "drop"
  )
}
