#' Standardizer render
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param smirks smirks
#' @param format format
#' @param width width
#' @param height height
#' @return The decoded service response, preserving JSON structure, text or media bytes.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_render <- function(smiles = NULL, smirks = NULL, format = "SVG", width = NULL, height = NULL) {
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "smirks" = smirks, "format" = format, "width" = width, "height" = height),
    list(
      smiles = list(type = "string"),
      smirks = list(type = "string"),
      format = list(default = "SVG", enum = list("PNG", "SVG"), type = "string"),
      width = list(format = "int32", type = "integer"),
      height = list(format = "int32", type = "integer")
    ),
    .api_validation$body_value,
    c(smiles = "query", smirks = "query", format = "query", width = "query", height = "query")
  )
  params <- base::list("smiles" = smiles, "smirks" = smirks, "format" = format, "width" = width, "height" = height)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["smirks"]]) && base::any(!base::nzchar(params[["smirks"]]))) {
    base::stop("Empty query parameter: smirks")
  }
  if (base::is.character(params[["format"]]) && base::any(!base::nzchar(params[["format"]]))) {
    base::stop("Empty query parameter: format")
  }
  if (base::is.character(params[["width"]]) && base::any(!base::nzchar(params[["width"]]))) {
    base::stop("Empty query parameter: width")
  }
  if (base::is.character(params[["height"]]) && base::any(!base::nzchar(params[["height"]]))) {
    base::stop("Empty query parameter: height")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/stdizer/render",
    path_params = base::list(),
    query = base::list(
      "smiles" = params[["smiles"]],
      "smirks" = params[["smirks"]],
      "format" = params[["format"]],
      "width" = params[["width"]],
      "height" = params[["height"]]
    ),
    body = NULL,
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
