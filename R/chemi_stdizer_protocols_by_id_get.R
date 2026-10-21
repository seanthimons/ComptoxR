#' Read records in a standardizer protocol
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id Protocol identifier returned by chemi_stdizer_protocols().
#' @param hidden Optional boolean filter; NULL leaves the service default.
#' @param components Optional boolean filter; NULL leaves the service default.
#' @param changed Optional boolean filter; NULL leaves the service default.
#' @param failed Optional boolean filter; NULL leaves the service default.
#' @param passed Optional boolean filter; NULL leaves the service default.
#' @param page Zero-based page index; NULL leaves the service default.
#' @param size Positive page size; NULL leaves the service default.
#' @param sort Character vector of sort expressions, such as c("type,asc", "id,desc"). Each expression is sent as its own sort query field. NULL or character() omits sorting.
#' @return Decoded protocol metadata and its requested page of records.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_protocols_by_id_get <- function(
  id,
  hidden = NULL,
  components = NULL,
  changed = NULL,
  failed = NULL,
  passed = NULL,
  page = NULL,
  size = NULL,
  sort = NULL
) {
  sort <- base::get(
    ".ct_protocol_sort",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(sort)
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  .api_validation$parameter_values(
    base::list(
      "id" = id,
      "hidden" = hidden,
      "components" = components,
      "changed" = changed,
      "failed" = failed,
      "passed" = passed,
      "page" = page,
      "size" = size,
      "sort" = sort
    ),
    list(
      id = list(type = "string"),
      hidden = list(type = "boolean"),
      components = list(type = "boolean"),
      changed = list(type = "boolean"),
      failed = list(type = "boolean"),
      passed = list(type = "boolean"),
      page = list(type = "integer", description = "page", minimum = 0L),
      size = list(type = "integer", description = "size", minimum = 1L),
      sort = list(type = "array", description = "sort", items = list(type = "string"))
    ),
    .api_validation$body_value,
    c(
      id = "path",
      hidden = "query",
      components = "query",
      changed = "query",
      failed = "query",
      passed = "query",
      page = "client",
      size = "client",
      sort = "client"
    )
  )
  params <- base::list(
    "id" = id,
    "hidden" = hidden,
    "components" = components,
    "changed" = changed,
    "failed" = failed,
    "passed" = passed,
    "page" = page,
    "size" = size,
    "sort" = sort
  )
  if (base::is.character(params[["hidden"]]) && base::any(!base::nzchar(params[["hidden"]]))) {
    base::stop("Empty query parameter: hidden")
  }
  if (base::is.character(params[["components"]]) && base::any(!base::nzchar(params[["components"]]))) {
    base::stop("Empty query parameter: components")
  }
  if (base::is.character(params[["changed"]]) && base::any(!base::nzchar(params[["changed"]]))) {
    base::stop("Empty query parameter: changed")
  }
  if (base::is.character(params[["failed"]]) && base::any(!base::nzchar(params[["failed"]]))) {
    base::stop("Empty query parameter: failed")
  }
  if (base::is.character(params[["passed"]]) && base::any(!base::nzchar(params[["passed"]]))) {
    base::stop("Empty query parameter: passed")
  }
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/stdizer/protocols/{id}",
    "path_params" = base::list("id" = params[["id"]]),
    "query" = base::list(
      "hidden" = params[["hidden"]],
      "components" = params[["components"]],
      "changed" = params[["changed"]],
      "failed" = params[["failed"]],
      "passed" = params[["passed"]],
      "page" = params[["page"]],
      "size" = params[["size"]],
      "sort" = params[["sort"]]
    ),
    "body" = NULL,
    "headers" = structure(list(), names = character(0)),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "query_serialization" = list(sort = "explode"),
    "body_media" = "application/json",
    "request_controls" = list(preserve_errors = TRUE),
    "parameter_serialization" = list(
      list(
        name = "hidden",
        location = "query",
        schema = list(type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = FALSE
      ),
      list(
        name = "components",
        location = "query",
        schema = list(type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = FALSE
      ),
      list(
        name = "changed",
        location = "query",
        schema = list(type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = FALSE
      ),
      list(
        name = "failed",
        location = "query",
        schema = list(type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = FALSE
      ),
      list(
        name = "passed",
        location = "query",
        schema = list(type = "boolean"),
        style = "form",
        explode = TRUE,
        collection_format = NULL,
        required = FALSE
      )
    )
  )
  result
}
