#' Services Convert
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param content Input structure content.
#' @param type Conversion type.
#' @return Converted text.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_services_convert <- function(content = NULL, type = NULL) {
  params <- base::list("content" = content, "type" = type)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/services/convert",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = .ct_services_body(
      params,
      structure(
        list(properties = list(content = list(type = "string"), type = list(type = "string")), type = "object"),
        specmill_id = "#/components/schemas/ConvertRequest"
      )
    ),
    "headers" = list(Accept = "*/*"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "request_controls" = list(preserve_errors = TRUE),
    "response_policy" = ".ct_services_convert_response"
  )
  result
}
