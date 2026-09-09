#' Returns the number of spectra that have a specified methodology.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DTXSID for the substance of interest.
#' @param spectrum_type Analytical methodology to search for.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_spectrum_count_for_methodology(dtxsid = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_spectrum_count_for_methodology <- function(dtxsid = NULL, spectrum_type = NULL) {
  params <- list("dtxsid" = dtxsid, "spectrum_type" = spectrum_type)
  result <- generic_chemi_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "amos/spectrum_count_for_methodology/",
    "options" = local({
      .body <- Filter(Negate(is.null), list("spectrum_type" = params[["spectrum_type"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
