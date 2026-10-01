#' Render a chemical structure image
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemical_id ChET chemical ID. Type: integer.
#' @param width Optional parameter
#' @param height Optional parameter
#' @param format Optional parameter. Options: png, svg, pdf (default: png)
#' @return A magick image for PNG or SVG, or raw bytes for PDF.
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_image(chemical_id = 1)
#' }
chemi_chet_chemicals_image <- function(chemical_id, width = NULL, height = NULL, format = "png") {
  # Collect optional parameters
  options <- list()
  if (!is.null(width)) {
    options[['width']] <- width
  }
  if (!is.null(height)) {
    options[['height']] <- height
  }
  if (!is.null(format)) {
    options[['format']] <- format
  }
  result <- generic_request(
    query = chemical_id,
    endpoint = "chet/chemicals",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = "image",
    content_type = "application/pdf, image/png, image/svg+xml",
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
