#' Get httk data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_httk(query = "DTXSID7020182")
#' }
ct_exposure_httk <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/httk/search/by-dtxsid/",
    method = "POST",
    batch_limit = NULL
  )
}

