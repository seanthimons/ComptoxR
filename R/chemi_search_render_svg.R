#' Chemi search render svg
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id id
#' @param query query
#' @param width width
#' @param height height
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_search_render_svg <- function(id, query = NULL, width = NULL, height = NULL) {
  if (base::is.null(id)) {
    base::stop("Required input: id")
  }
  .api_validation$parameter_values(
    base::list("id" = id, "query" = query, "width" = width, "height" = height),
    list(
      id = list(format = "int32", type = "integer"),
      query = list(type = "string"),
      width = list(format = "int32", type = "integer"),
      height = list(format = "int32", type = "integer")
    ),
    .api_validation$body_value,
    c(id = "query", query = "query", width = "query", height = "query")
  )
  params <- base::list("id" = id, "query" = query, "width" = width, "height" = height)
  if (base::is.character(params[["id"]]) && base::any(!base::nzchar(params[["id"]]))) {
    base::stop("Empty query parameter: id")
  }
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["width"]]) && base::any(!base::nzchar(params[["width"]]))) {
    base::stop("Empty query parameter: width")
  }
  if (base::is.character(params[["height"]]) && base::any(!base::nzchar(params[["height"]]))) {
    base::stop("Empty query parameter: height")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/search/render/svg",
    path_params = base::list(),
    query = base::list(
      "id" = params[["id"]],
      "query" = params[["query"]],
      "width" = params[["width"]],
      "height" = params[["height"]]
    ),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
