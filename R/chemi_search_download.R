#' Chemi search download
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body Request body.
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_search_download <- function(body) {
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
              format = list(type = "string"),
              ids = list(
                items = structure(
                  list(
                    properties = list(
                      id = list(format = "int32", type = "integer"),
                      sim = list(format = "float", type = "number")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/DownloadItem"
                ),
                type = "array"
              ),
              query = list(type = "string")
            ),
            type = "object"
          ),
          specmill_id = "#/components/schemas/DownloadRequest"
        )
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/api/search/download",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
