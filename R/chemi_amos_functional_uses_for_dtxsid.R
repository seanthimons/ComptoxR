#' Returns a list of functional use classifications for a substance.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_functional_uses_for_dtxsid(dtxsid = "DTXSID7020182")
#' }
chemi_amos_functional_uses_for_dtxsid <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "amos/functional_uses_for_dtxsid/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


