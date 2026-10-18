#' chemi amos mass spectrum similarity
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param lower_mass_limit Lower limit of the mass range to search for.
#' @param methodology Analytical methodology to search for.  Values aside from "GC/MS" and "LC/MS" are highly unlikely to produce results.
#' @param spectrum Array of two-element numeric arrays.  The two-element arrays represent a single peak in the spectrum, in the format \[m/z, intensity\].  Peaks should be sorted in ascending order of m/z values.
#' @param type Type of mass window to use for entropy similarity calculations.  Can be either "da" or "ppm".
#' @param upper_mass_limit Upper limit of the mass range to search for.
#' @param window Size of mass window.  Is in units of \code{type}.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectrum_similarity(lower_mass_limit = 194.1, methodology = "LC/MS", spectrum = list(list(217.0696, 100L), list(218.0721, 10.2292)), type = "da", upper_mass_limit = 194.2, window = 0.05)
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_mass_spectrum_similarity <- function(
  lower_mass_limit = NULL,
  methodology = NULL,
  spectrum = NULL,
  type = NULL,
  upper_mass_limit = NULL,
  window = NULL
) {
  params <- base::list(
    "lower_mass_limit" = lower_mass_limit,
    "methodology" = methodology,
    "spectrum" = spectrum,
    "type" = type,
    "upper_mass_limit" = upper_mass_limit,
    "window" = window
  )
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/mass_spectrum_similarity_search/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      value <- params[["lower_mass_limit"]]
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
              lower_mass_limit = list(
                description = "Lower limit of the mass range to search for.",
                example = 194.1,
                type = "number"
              ),
              methodology = list(
                description = "Analytical methodology to search for.  Values aside from \"GC/MS\" and \"LC/MS\" are highly unlikely to produce results.",
                example = "LC/MS",
                type = "string"
              ),
              spectrum = list(
                description = "Array of two-element numeric arrays.  The two-element arrays represent a single peak in the spectrum, in the format [m/z, intensity].  Peaks should be sorted in ascending order of m/z values.",
                example = list(list(217.0696, 100L), list(218.0721, 10.2292)),
                items = list(type = "array", items = list()),
                type = "array"
              ),
              type = list(
                description = "Type of mass window to use for entropy similarity calculations.  Can be either \"da\" or \"ppm\".",
                example = "da",
                type = "string"
              ),
              upper_mass_limit = list(
                description = "Upper limit of the mass range to search for.",
                example = 194.2,
                type = "number"
              ),
              window = list(
                description = "Size of mass window.  Is in units of `type`.",
                example = 0.05,
                type = "number"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/mass_spectrum_similarity_search_request"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/mass_spectrum_similarity_search/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
