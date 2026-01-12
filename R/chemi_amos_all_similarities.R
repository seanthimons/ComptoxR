#' Given a list of DTXSIDs and a list of mass spectra, return a highest similarity score for each combination of DTXSID and spectrum.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A list of DTXSIDs to search for
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_all_similarities(query = "DTXSID7020182")
#' }
chemi_amos_all_similarities <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/all_similarities_by_dtxsid/",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


