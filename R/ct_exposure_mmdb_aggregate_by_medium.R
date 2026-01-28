#' Get Aggregate data by Medium
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param medium harmonized medium
#' @param pageNumber Optional parameter (default: 1)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_aggregate_by_medium(medium = "surface water")
#' }
ct_exposure_mmdb_aggregate_by_medium <- function(medium, pageNumber = 1) {
  result <- generic_request(
    endpoint = "exposure/mmdb/aggregate/by-medium",
    method = "GET",
    batch_limit = 0,
    `medium` = medium,
    `pageNumber` = pageNumber
  )

  # Additional post-processing can be added here

  return(result)
}


