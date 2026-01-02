#' Retrieves a list of methods that contain the MS-Ready forms of a given substance but not the substance itself.
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
#' chemi_amos_amos_get_ms_ready_methods(query = "DTXSID7020182")
#' }
chemi_amos_amos_get_ms_ready_methods <- function(query) {
  generic_chemi_request(
    query = query,
    endpoint = "api/amos/get_ms_ready_methods/",
    server = "chemi_burl",
    auth = FALSE
  )
}

