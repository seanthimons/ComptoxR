#' Get chemicals by starting value
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param word word Accepts a vector: one request is sent per element and the results are combined.
#' @param top top
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_start_with(word = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_start_with <- function(word, top = 500L) {
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
    base::list("word" = word, "top" = top),
    list(
      word = list(type = "array", items = list(type = "string")),
      top = list(default = 500L, format = "int32", type = "integer")
    ),
    .api_validation$body_value,
    c(word = "path", top = "query")
  )
  params <- base::list("word" = word, "top" = top)
  if (base::is.character(params[["top"]]) && base::any(!base::nzchar(params[["top"]]))) {
    base::stop("Empty query parameter: top")
  }
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/search/start-with/{word}",
      path_params = base::list("word" = params[["word"]]),
      query = base::list("top" = params[["top"]]),
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
    on_error = "drop"
  )
}
