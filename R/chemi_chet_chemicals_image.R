#' Render a chemical structure image
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemical_id Primary query parameter. Type: integer
#' @param width Optional parameter
#' @param height Optional parameter
#' @param format Optional parameter. Options: png, svg, pdf (default: png)
#' @return Returns image data (raw bytes or magick image object)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_image(chemical_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_image <- function(chemical_id, width = NULL, height = NULL, format = "png") {
  params <- list("chemical_id" = chemical_id, "width" = width, "height" = height, "format" = format)
  result <- generic_request(
    "query" = params[["chemical_id"]],
    "endpoint" = "chemicals/image",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "content_type" = "application/pdf, image/png, image/svg+xml",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("width" = params[["width"]], "height" = params[["height"]], "format" = params[["format"]])
      )
      if (length(.body)) .body else list()
    })
  )
  result
}
