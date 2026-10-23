#' chemi amos all similarities
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param da_window Mass window in units of daltons.  If not null, this will be used for similarity calculations, regardless of whether ppm_window is supplied.
#' @param dtxsids List of DTXSIDs to search for.
#' @param min_intensity Minimum intensity level for peaks in both the user and database spectra to consider.  All database spectra are scaled to have a maximum intensity of 100, and all user spectra are assumed to be scaled the same.
#' @param ms_level Level of mass spectrometry; if supplied, then only spectra at the specified level will be returned.  Valid values are from 1 to 5.
#' @param ppm_window Mass window in units of parts per million.  Will only be used if da_window is null or not passed and ppm_window is not null.
#' @param spectra A list of spectra, where each spectrum is an array of m/z-intensity pairs formatted as two-element arrays.  Maximum intensity should be scaled to 100.
#' @return The decoded JSON result from the AMOS read or calculation operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_all_similarities(da_window = 0.1, dtxsids = list("DTXSID9020112", "DTXSID3022401"), min_intensity = 0, ms_level = 2L, ppm_window = 5, spectra = list(list(list(10L, 20L), list(23L, 100L)), list(list(15L, 30L), list(24.5, 100L), list(33L, 9L))))
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_all_similarities <- function(
  da_window = NULL,
  dtxsids = NULL,
  min_intensity = NULL,
  ms_level = NULL,
  ppm_window = NULL,
  spectra = NULL
) {
  params <- base::list(
    "da_window" = da_window,
    "dtxsids" = dtxsids,
    "min_intensity" = min_intensity,
    "ms_level" = ms_level,
    "ppm_window" = ppm_window,
    "spectra" = spectra
  )
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/all_similarities_by_dtxsid/",
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
                example = list("DTXSID9020112", "DTXSID3022401"),
                items = list(type = "string"),
                type = "array"
              ),
              min_intensity = list(
                description = "Minimum intensity level for peaks in both the user and database spectra to consider.  All database spectra are scaled to have a maximum intensity of 100, and all user spectra are assumed to be scaled the same.",
                example = 0L,
                type = "number"
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
                description = "A list of spectra, where each spectrum is an array of m/z-intensity pairs formatted as two-element arrays.  Maximum intensity should be scaled to 100.",
                example = list(
                  list(list(10L, 20L), list(23L, 100L)),
                  list(list(15L, 30L), list(24.5, 100L), list(33L, 9L))
                ),
                items = list(type = "array", items = list()),
                type = "array"
              )
            ),
            type = "object"
          ),
          specmill_id = "#/definitions/all_similarity_by_dtxsid_request"
        )
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Reviewed AMOS production origin."),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/all_similarities_by_dtxsid/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
