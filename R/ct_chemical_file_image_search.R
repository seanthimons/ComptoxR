#' Get structure image by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid dtxsid Accepts a vector: one request is sent per element and the results are combined.
#' @return An image object or raw bytes for one identifier, or an unnamed list for multiple identifiers.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_file_image_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_file_image_search <- function(dtxsid) {
  dtxsid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxsid)
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(dtxsid = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/chemical/file/image/search/by-dtxsid/{dtxsid}",
      "path_params" = base::list("dtxsid" = params[["dtxsid"]]),
      "query" = structure(list(), names = character(0)),
      "body" = NULL,
      "headers" = list(Accept = "image/png"),
      "server" = list(url = "https://comptox.epa.gov/ctx-api"),
      "server_resolver" = list(name = ".ct_server_url", key = "ctx_burl"),
      "auth" = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      ))),
      "response_policy" = function(response, context, decode) {
        .ct_collect_response(response, context, decode, length(dtxsid), "chemical/file/image/search/by-dtxsid/")
      }
    )
    result
  }
  result <- .ct_request_each(
    function(chunk) {
      params["dtxsid"] <- base::list(chunk)
      send(params)
    },
    params[["dtxsid"]],
    1L,
    on_error = list(single = "stop", multiple = "drop"),
    warning = FALSE
  )
  base::attr(result, "failed") <- NULL
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  base::get(
    "format_image_results",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = FALSE
  )(base::list(result = result, params = params))
}
