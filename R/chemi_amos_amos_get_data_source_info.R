#' Returns a list of major data sources in AMOS with some supplemental information.
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
#' chemi_amos_amos_get_data_source_info(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_data_source_info <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_data_source_info/",
    server = "chemi_burl",
    auth = FALSE
  )
}

