#' Given a list of DTXSIDs, return all mass spectra for those substances.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsids List of DTXSIDs to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_mass_spectra_for_substances(dtxsids = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_mass_spectra_for_substances <- function(dtxsids = NULL) {
  params <- list("dtxsids" = dtxsids)
  result <- generic_chemi_request(
    "query" = params[["dtxsids"]],
    "endpoint" = "amos/mass_spectra_for_substances/",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
