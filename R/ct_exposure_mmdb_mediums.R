#' Get all Media options
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_mediums(query = "DTXSID7020182")
#' }
ct_exposure_mmdb_mediums <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/mmdb/mediums",
    method = "GET",
    batch_limit = 1
  )
}

