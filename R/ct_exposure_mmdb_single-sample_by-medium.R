#' Get Single Sample data by Medium
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param medium harmonized medium
#' @param pageNumber Optional parameter (default: 1)
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_single_sample_by_medium(medium = "surface water")
#' }
ct_exposure_mmdb_single_sample_by_medium <- function(medium, pageNumber = 1, all_pages = TRUE) {
  result <- generic_request(
    endpoint = "exposure/mmdb/single-sample/by-medium",
    method = "GET",
    batch_limit = 0,
    `medium` = medium,
    `pageNumber` = pageNumber,
    paginate = all_pages,
    max_pages = 100,
    pagination_strategy = "page_number"
  )

  # Additional post-processing can be added here

  return(result)
}


