#' Get lists by name
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param listName listName Accepts a vector: one request is sent per element and the results are combined.
#' @param projection Projection options for chemical List APIs
#' @param extract_dtxsids Extract DTXSIDs from results into character vector (requires projection = 'chemicallistwithdtxsids')
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_search_by_name(listName = "40CFR1164")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_search_by_name <- function(listName, projection = "chemicallistall", extract_dtxsids = FALSE) {
  original_params <- base::list("listName" = listName, "projection" = projection, "extract_dtxsids" = extract_dtxsids)
  listName <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(listName)
  if (base::is.null(listName)) {
    base::stop("Required input: listName")
  }
  .api_validation$parameter_values(
    base::list("listName" = listName, "projection" = projection),
    list(
      listName = list(type = "array", items = list(type = "string")),
      projection = list(
        description = "Projection options for chemical List APIs ",
        enum = list("chemicallistall", "chemicallistwithdtxsids", "chemicallistname", "ccdchemicaldetaillists"),
        type = "string",
        default = "chemicallistall"
      )
    ),
    .api_validation$body_value,
    c(listName = "path", projection = "query")
  )
  params <- base::list("listName" = listName, "projection" = projection, "extract_dtxsids" = extract_dtxsids)
  if (base::is.character(params[["projection"]]) && base::any(!base::nzchar(params[["projection"]]))) {
    base::stop("Empty query parameter: projection")
  }
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/chemical/list/search/by-name/{listName}",
      "path_params" = base::list("listName" = params[["listName"]]),
      "query" = base::list("projection" = params[["projection"]]),
      "body" = NULL,
      "server" = list(url = "https://comptox.epa.gov/ctx-api"),
      "server_resolver" = list(name = ".ct_server_url", key = "ctx_burl"),
      "response_policy" = function(response, context, decode) {
        .ct_collect_response(response, context, decode, length(listName), "chemical/list/search/by-name/")
      },
      "headers" = list(Accept = "application/json"),
      "auth" = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      ))),
      "request_controls" = list(preserve_errors = TRUE)
    )
    result
  }
  result <- .ct_request_each(
    function(chunk) {
      params["listName"] <- base::list(chunk)
      send(params)
    },
    params[["listName"]],
    1L,
    on_error = list(single = "stop", multiple = "drop"),
    warning = FALSE
  )
  base::attr(result, "failed") <- NULL
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  result <- base::get(
    "format_legacy_tidy_result",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = FALSE
  )(base::list(result = result, params = params))
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  result <- run_hook(
    "ct_chemical_list_search_by_name",
    "post_response",
    base::list(result = result, params = original_params)
  )
  result
}
