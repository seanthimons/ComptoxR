#' Render a chemical structure image
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemical_id ChET chemical ID. Type: integer.
#' @param width Optional parameter
#' @param height Optional parameter
#' @param format Optional parameter. Options: png, svg, pdf (default: png)
#' @return A magick image for PNG or SVG, or raw bytes for PDF.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_image(chemical_id = 1)
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_image <- function(chemical_id, width = NULL, height = NULL, format = "png") {
  chemical_id <- base::get(
    ".ct_single_path_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(chemical_id)
  params <- base::list("chemical_id" = chemical_id, "width" = width, "height" = height, "format" = format)
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/chet/chemicals/{chemical_id}/image",
    "path_params" = base::list("chemical_id" = params[["chemical_id"]]),
    "query" = base::list("width" = params[["width"]], "height" = params[["height"]], "format" = params[["format"]]),
    "body" = NULL,
    "headers" = list(Accept = "application/pdf, image/png, image/svg+xml"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$query <- params[["chemical_id"]]
      .ct_chet_image_result(response, context, decode)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
