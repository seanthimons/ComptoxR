#' chemi amos spectral entropy
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param spectrum Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_spectral_entropy(spectrum = list(list(10.5, 20L), list(20L, 100L), list(50L, 1L)))
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_spectral_entropy <- function(spectrum = NULL) {
  params <- base::list("spectrum" = spectrum)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/spectral_entropy/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      value <- params[["spectrum"]]
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
              spectrum = list(
                description = "Array of m/z intensity pairs.  Should be formatted as an array of two-element arrays, each of which has the m/z value and the intensity value (in that order).  Peaks should be sorted in increasing order of m/z values.",
                example = list(list(10.5, 20L), list(20L, 100L), list(50L, 1L)),
                items = list(type = "array", items = list()),
                type = "array"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/spectral_entropy_request"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/spectral_entropy/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
