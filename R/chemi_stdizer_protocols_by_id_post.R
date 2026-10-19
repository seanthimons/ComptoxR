#' Search records in a standardizer protocol
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Search criteria as a named list. Use list() for an unfiltered search; optional flags include hidden, components, changed, failed and passed.
#' @param id Protocol identifier returned by chemi_stdizer_protocols().
#' @param page Zero-based page index; NULL leaves the service default.
#' @param size Positive page size; NULL leaves the service default.
#' @param sort Character vector of sort expressions, such as c("type,asc", "id,desc"). Each expression is sent as its own sort query field. NULL or character() omits sorting.
#' @param body Request body.
#' @return Decoded protocol metadata and its requested page of records.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_protocols_by_id_post <- function(id, page = NULL, size = NULL, sort = NULL, body) {
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
    base::list("id" = id, "page" = page, "size" = size, "sort" = sort),
    list(
      id = list(type = "string"),
      page = list(format = "int32", minimum = 0L, type = "integer"),
      size = list(format = "int32", minimum = 1L, type = "integer"),
      sort = list(items = list(type = "string"), type = "array")
    ),
    .api_validation$body_value,
    c(id = "path", page = "query", size = "query", sort = "query")
  )
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(
        body,
        structure(
          list(
            properties = list(
              change = list(type = "string"),
              changed = list(type = "boolean"),
              components = list(type = "boolean"),
              failed = list(type = "boolean"),
              hidden = list(type = "boolean"),
              issue = list(type = "string"),
              passed = list(type = "boolean"),
              query = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/ProtocolSearchRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("id" = id, "page" = page, "size" = size, "sort" = sort, "body" = body)
  if (base::is.character(params[["page"]]) && base::any(!base::nzchar(params[["page"]]))) {
    base::stop("Empty query parameter: page")
  }
  if (base::is.character(params[["size"]]) && base::any(!base::nzchar(params[["size"]]))) {
    base::stop("Empty query parameter: size")
  }
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/stdizer/protocols/{id}",
    "path_params" = base::list("id" = params[["id"]]),
    "query" = base::list("page" = params[["page"]], "size" = params[["size"]], "sort" = params[["sort"]]),
    "body" = params[["body"]],
    "headers" = structure(list(), names = character(0)),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "query_serialization" = list(sort = "explode"),
    "body_media" = "application/json",
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
