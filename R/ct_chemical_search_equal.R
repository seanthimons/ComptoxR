#' Get chemicals by exact value
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param word word Accepts a vector: one request is sent per element and the results are combined.
#' @param projection projection
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_equal(word = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_equal <- function(word, projection = "chemicalsearchall") {
  word <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(word)
  if (base::is.null(word)) {
    base::stop("Required input: word")
  }
  .api_validation$parameter_values(
    base::list("word" = word, "projection" = projection),
    list(
      word = list(type = "array", items = list(type = "string")),
      projection = list(default = "chemicalsearchall", type = "string")
    ),
    .api_validation$body_value,
    c(word = "path", projection = "query")
  )
  params <- base::list("word" = word, "projection" = projection)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/search/equal/{word}",
      path_params = base::list("word" = params[["word"]]),
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
      params["word"] <- base::list(chunk)
      send(params)
    },
    params[["word"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
