#' Render a chemical structure image
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemical_id Primary query parameter. Type: integer
#' @param width Optional parameter
#' @param height Optional parameter
#' @param format Optional parameter. Options: png, svg, pdf (default: png)
#' @return Returns image data (raw bytes or magick image object)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_image(chemical_id = "DTXSID7020182")
#' }
chemi_chet_chemicals_image <- function(chemical_id, width = NULL, height = NULL, format = "png") {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_chemicals_image", "pre_request", list(params = list(`chemical_id` = chemical_id, `width` = width, `height` = height, `format` = format, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("chemical_id" %in% names(req_data$params)) {
    chemical_id <- req_data$params[["chemical_id"]]
  }
  if ("width" %in% names(req_data$params)) {
    width <- req_data$params[["width"]]
  }
  if ("height" %in% names(req_data$params)) {
    height <- req_data$params[["height"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(width)) options[['width']] <- width
  if (!is.null(height)) options[['height']] <- height
  if (!is.null(format)) options[['format']] <- format
    result <- generic_request(
    query = chemical_id,
    endpoint = "chemicals/image",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    content_type = "application/pdf, image/png, image/svg+xml",
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
