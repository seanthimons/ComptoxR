# Generated with specmill; do not edit by hand.
chemi_chet_reaction_searchcounts <- function(search_input, search_type = NULL) {
  search_input <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(search_input)
  if (base::is.null(search_input)) {
    base::stop("Required input: search_input")
  }
  .api_validation$parameter_values(
    base::list("search_input" = search_input, "search_type" = search_type),
    list(
      search_input = list(type = "array", items = list(type = "string")),
      search_type = list(type = "string")
    ),
    .api_validation$body_value,
    c(search_input = "path", search_type = "path")
  )
  params <- base::list(
    "search_input" = search_input,
    "search_type" = search_type
  )
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = base::local({
        trailing <- params[["search_type"]]
        if (length(trailing) && length(search_input) > 1L) {
          cli::cli_abort(
            "Cannot use path_params with batching. Path parameter endpoints do not support batch queries."
          )
        }
        paste0(
          "/api/chet",
          "/reaction/searchcounts",
          "/{",
          "search_input",
          "}",
          if (length(trailing)) {
            paste0("/", paste(as.character(trailing), collapse = "/"))
          } else {
            ""
          }
        )
      }),
      "path_params" = base::list("search_input" = params[["search_input"]]),
      "query" = structure(list(), names = character(0)),
      "body" = NULL,
      "headers" = list(Accept = "application/json"),
      "server" = list(url = "https://hcd.rtpnc.epa.gov"),
      "server_resolver" = list(
        name = ".ct_server_url",
        key = "chemi_burl",
        relative = "/"
      ),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        .ct_collect_response(
          response,
          context,
          decode,
          length(search_input),
          "chet/reaction/searchcounts/"
        )
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
    result
  }
  result <- .ct_request_each(
    function(chunk) {
      params["search_input"] <- base::list(chunk)
      send(params)
    },
    params[["search_input"]],
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
    "format_legacy_list_result",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = FALSE
  )(base::list(result = result, params = params))
}
