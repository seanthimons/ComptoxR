#' Get Aggregate data by Medium
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param medium harmonized medium
#' @param pageNumber Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_aggregate_by_medium(query = "DTXSID7020182")
#' }
ct_exposure_mmdb_aggregate_by_medium <- function(query, medium = NULL, pageNumber = NULL) {
  generic_request(
    query = query,
    endpoint = "exposure/mmdb/aggregate/by-medium",
    method = "GET",
    batch_limit = 1,
    medium = medium,
    pageNumber = pageNumber
  )
}

