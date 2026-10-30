#' chemi amos entropy similarity
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param spectrum_1 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param spectrum_2 Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @param type Type of mass window to use.  Should be either "da" or "ppm".
#' @param window Size of the mass window to use.  Will be in units of the 'type' argument.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_entropy_similarity(spectrum_1 = list(list(10.5, 20L), list(20L, 100L), list(50L, 1L)), spectrum_2 = list(list(10.5, 20L), list(22L, 100L), list(50L, 1.5)), type = "da", window = 0.1)
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_entropy_similarity <- function(spectrum_1 = NULL, spectrum_2 = NULL, type = NULL, window = NULL) {
  params <- base::list("spectrum_1" = spectrum_1, "spectrum_2" = spectrum_2, "type" = type, "window" = window)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/entropy_similarity/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      value <- params[["spectrum_1"]]
      if (base::is.null(value) || !base::length(value)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      if (base::is.atomic(value) && base::all(base::is.na(value) | value == "")) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      body <- base::Filter(base::Negate(base::is.null), params)
      .api_validation$body_value(
        body,
        structure(
          list(
            properties = list(
              spectrum_1 = list(
                description = "Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.",
                example = list(list(10.5, 20L), list(20L, 100L), list(50L, 1L)),
                items = list(type = "array", items = list()),
                type = "array"
              ),
              spectrum_2 = list(
                description = "Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.",
                example = list(list(10.5, 20L), list(22L, 100L), list(50L, 1.5)),
                items = list(type = "array", items = list()),
                type = "array"
              ),
              type = list(
                description = "Type of mass window to use.  Should be either \"da\" or \"ppm\".",
                example = "da",
                type = "string"
              ),
              window = list(
                description = "Size of the mass window to use.  Will be in units of the 'type' argument.",
                example = 0.1,
                type = "number"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/entropy_similarity_request"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/entropy_similarity/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
