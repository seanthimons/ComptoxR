#' chemi amos mass range
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param lower_mass_limit Lower limit of the mass range to search for.
#' @param upper_mass_limit Upper limit of the mass range to search for.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_mass_range(lower_mass_limit = 194.1, upper_mass_limit = 194.2)
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_mass_range <- function(lower_mass_limit = NULL, upper_mass_limit = NULL) {
  params <- base::list("lower_mass_limit" = lower_mass_limit, "upper_mass_limit" = upper_mass_limit)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/mass_range_search/",
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
              upper_mass_limit = list(
                description = "Upper limit of the mass range to search for.",
                example = 194.2,
                type = "number"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/MassRangeSubstanceSearchRequest"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/mass_range_search/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
