#' chemi amos max similarity
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param da_window Mass window in units of daltons.  If not null, this will be used for similarity calculations, regardless of whether ppm_window is supplied.
#' @param dtxsids List of DTXSIDs to search for.
#' @param ms_level Level of mass spectrometry; if supplied, then only spectra at the specified level will be returned.  Valid values are from 1 to 5.
#' @param ppm_window Mass window in units of parts per million.  Will only be used if da_window is null or not passed and ppm_window is not null.
#' @param spectra A list of spectra, where each spectrum is an array of m/z-intensity pairs formatted as two-element arrays.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_max_similarity_by_dtxsid(da_window = 0.1, dtxsids = list("DTXSID0020232", "DTXSID70199859"), ms_level = 2L, ppm_window = 5, spectra = list(list(list(217.0696, 100L), list(218.0721, 10.2292))))
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_max_similarity_by_dtxsid <- function(
  da_window = NULL,
  dtxsids = NULL,
  ms_level = NULL,
  ppm_window = NULL,
  spectra = NULL
) {
  params <- base::list(
    "da_window" = da_window,
    "dtxsids" = dtxsids,
    "ms_level" = ms_level,
    "ppm_window" = ppm_window,
    "spectra" = spectra
  )
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/max_similarity_by_dtxsid/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      value <- params[["da_window"]]
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
              da_window = list(
                description = "Mass window in units of daltons.  If not null, this will be used for similarity calculations, regardless of whether ppm_window is supplied.",
                example = 0.1,
                type = "number"
              ),
              dtxsids = list(
                description = "List of DTXSIDs to search for.",
                example = list("DTXSID0020232", "DTXSID70199859"),
                items = list(type = "string"),
                type = "array"
              ),
              ms_level = list(
                description = "Level of mass spectrometry; if supplied, then only spectra at the specified level will be returned.  Valid values are from 1 to 5.",
                example = 2L,
                type = "integer"
              ),
              ppm_window = list(
                description = "Mass window in units of parts per million.  Will only be used if da_window is null or not passed and ppm_window is not null.",
                example = 5L,
                type = "number"
              ),
              spectra = list(
                description = "A list of spectra, where each spectrum is an array of m/z-intensity pairs formatted as two-element arrays.",
                example = list(list(list(217.0696, 100L), list(218.0721, 10.2292))),
                items = list(type = "array", items = list()),
                type = "array"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/max_similarity_by_dtxsid_request"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/max_similarity_by_dtxsid/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
