#' Returns a list of substances whose monoisotopic mass falls within the specified range.
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
#' chemi_amos_amos_mass_range(query = "DTXSID7020182")
#' }
chemi_amos_amos_mass_range <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/mass_range_search/",
    server = "chemi_burl",
    auth = FALSE
  )
}

