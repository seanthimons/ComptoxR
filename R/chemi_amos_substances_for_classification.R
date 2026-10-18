#' chemi amos substances for classification
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param kingdom Kingdom-level (highest) classification of a substance.
#' @param klass Class-level (third-highest) classification of a substance.
#' @param subklass Subclass-level (fourth-highest) classification of a substance.
#' @param superklass Superclass-level (second-highest) classification of a substance.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_substances_for_classification(kingdom = "Organic compounds", klass = "Organic metal salts", subklass = "Organic calcium salts", superklass = "Organic salts")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_substances_for_classification <- function(kingdom = NULL, klass = NULL, subklass = NULL, superklass = NULL) {
  params <- base::list("kingdom" = kingdom, "klass" = klass, "subklass" = subklass, "superklass" = superklass)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/substances_for_classification/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      value <- params[["kingdom"]]
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
              kingdom = list(
                description = "Kingdom-level (highest) classification of a substance.",
                example = "Organic compounds",
                type = "string"
              ),
              klass = list(
                description = "Class-level (third-highest) classification of a substance.",
                example = "Organic metal salts",
                type = "string"
              ),
              subklass = list(
                description = "Subclass-level (fourth-highest) classification of a substance.",
                example = "Organic calcium salts",
                type = "string"
              ),
              superklass = list(
                description = "Superclass-level (second-highest) classification of a substance.",
                example = "Organic salts",
                type = "string"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/ClassyFireClassificationRequest"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/substances_for_classification/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
