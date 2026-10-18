#' Given a list of DTXSIDs, return all mass spectra for those substances.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsids List of DTXSIDs to search for.
#' @return The decoded JSON result from the AMOS read operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectra_for_substances(dtxsids = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_mass_spectra_for_substances <- function(dtxsids = NULL) {
  dtxsids <- base::get(
    ".ct_amos_identifier_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(dtxsids)
  params <- base::list("dtxsids" = dtxsids)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/mass_spectra_for_substances/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = .api_validation$body_value(
      stats::setNames(base::list(params[["dtxsids"]]), "dtxsids"),
      structure(
        list(
          properties = list(
            dtxsids = list(
              description = "List of DTXSIDs to search for.",
              example = list("DTXSID9020112"),
              items = list(type = "string"),
              type = "array"
            )
          ),
          type = "object"
        ),
        specmill_id = "#/definitions/mass_spectra_for_substances_request"
      )
    ),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/mass_spectra_for_substances/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
