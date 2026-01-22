#' Retrieves known hazard and risk characterizations by DTXSID for skin and eye endpoints.
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_skin_eye(query = "DTXSID7020182")
#' }
ct_skin_eye <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/skin-eye/search/by-dtxsid/",
    method = "POST"
  )
}
