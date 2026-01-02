#' Given a list of DTXSIDs and a list of mass spectra, return a highest similarity score for each combination of DTXSID and spectrum.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_amos_max_similarity(query = "DTXSID7020182")
#' }
chemi_amos_amos_max_similarity <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/max_similarity_by_dtxsid/",
    server = "chemi_burl",
    auth = FALSE
  )
}

