#' Get DTXSIDs for list and containing starting string in chemical name
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param list list Accepts a vector: one request is sent per element and the results are combined.
#' @param word word
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_search_start_with(list = "TOXCAST", word = "bisphenol")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_chemicals_search_start_with <- function(list, word) {
  if (base::is.null(list)) {
    base::stop("Required input: list")
  }
  if (base::is.null(word)) {
    base::stop("Required input: word")
  }
  .api_validation$parameter_values(
    base::list("list" = list, "word" = word),
    list(list = list(type = "array", items = list(type = "string")), word = list(type = "string")),
    .api_validation$body_value,
    c(list = "path", word = "path")
  )
  params <- base::list("list" = list, "word" = word)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/chemical/list/chemicals/search/start-with/{list}/{word}",
      path_params = base::list("list" = params[["list"]], "word" = params[["word"]]),
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
      params["list"] <- base::list(chunk)
      send(params)
    },
    params[["list"]],
    1L,
    on_error = "drop"
  )
}
