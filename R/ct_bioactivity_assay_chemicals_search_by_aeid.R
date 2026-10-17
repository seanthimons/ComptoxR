#' Get DTXSID list by AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid aeid Accepts a vector: one request is sent per element and the results are combined.
#' @param projection projection
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_chemicals_search_by_aeid(aeid = 3032L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_chemicals_search_by_aeid <- function(aeid, projection = "dtxsidsonly") {
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
    base::list("aeid" = aeid, "projection" = projection),
    list(
      aeid = list(type = "array", items = list(format = "int32", type = "integer")),
      projection = list(default = "dtxsidsonly", type = "string")
    ),
    .api_validation$body_value,
    c(aeid = "path", projection = "query")
  )
  params <- base::list("aeid" = aeid, "projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/assay/chemicals/search/by-aeid/{aeid}",
      path_params = base::list("aeid" = params[["aeid"]]),
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
      params["aeid"] <- base::list(chunk)
      send(params)
    },
    params[["aeid"]],
    1L,
    on_error = "drop"
  )
}
