#' Returns a list of substances whose monoisotopic mass falls within the specified range.
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
#' chemi_amos_mass_range(query = "DTXSID7020182")
#' }
chemi_amos_mass_range <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "amos/mass_range_search/",
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


