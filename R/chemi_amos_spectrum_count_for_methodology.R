#' chemi amos spectrum count for methodology
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DTXSID for the substance of interest.
#' @param spectrum_type Analytical methodology to search for.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_spectrum_count_for_methodology(dtxsid = "DTXSID9020112", spectrum_type = "GC/MS")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_spectrum_count_for_methodology <- function(dtxsid = NULL, spectrum_type = NULL) {
  params <- base::list("dtxsid" = dtxsid, "spectrum_type" = spectrum_type)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/spectrum_count_for_methodology/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      value <- params[["dtxsid"]]
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
              dtxsid = list(
                description = "DTXSID for the substance of interest.",
                example = "DTXSID9020112",
                type = "string"
              ),
              spectrum_type = list(
                description = "Analytical methodology to search for.",
                example = "GC/MS",
                type = "string"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/spectrum_count_for_methodology_request"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/spectrum_count_for_methodology/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
