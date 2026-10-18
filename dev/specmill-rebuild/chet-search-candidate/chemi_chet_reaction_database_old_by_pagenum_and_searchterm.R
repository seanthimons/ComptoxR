# Generated with specmill; do not edit by hand.
chemi_chet_reaction_database_old_by_pagenum_and_searchterm <- function(
  pagenum,
  searchterm = NULL
) {
  pagenum <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(pagenum)
  if (base::is.null(pagenum)) {
    base::stop("Required input: pagenum")
  }
  .api_validation$parameter_values(
    base::list("pagenum" = pagenum, "searchterm" = searchterm),
    list(
      pagenum = list(type = "array", items = list(type = "integer")),
      searchterm = list(type = "string")
    ),
    .api_validation$body_value,
    c(pagenum = "path", searchterm = "path")
  )
  params <- base::list("pagenum" = pagenum, "searchterm" = searchterm)
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = base::local({
        trailing <- params[["searchterm"]]
        if (length(trailing) && length(pagenum) > 1L) {
          cli::cli_abort(
            "Cannot use path_params with batching. Path parameter endpoints do not support batch queries."
          )
        }
        paste0(
          "/api/chet",
          "/reaction/database-old",
          "/{",
          "pagenum",
          "}",
          if (length(trailing)) {
            paste0("/", paste(as.character(trailing), collapse = "/"))
          } else {
            ""
          }
        )
      }),
      "path_params" = base::list("pagenum" = params[["pagenum"]]),
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
          length(pagenum),
          "chet/reaction/database-old/"
        )
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
    result
  }
  result <- .ct_request_each(
    function(chunk) {
      params["pagenum"] <- base::list(chunk)
      send(params)
    },
    params[["pagenum"]],
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
