#' Get Single Sample data by Medium
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param medium harmonized medium
#' @param pageNumber Optional parameter (default: 1)
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_single_sample_by_medium(medium = "surface water")
#' }
# Generated with specmill; do not edit by hand.
ct_exposure_mmdb_single_sample_by_medium <- function(medium, pageNumber = 1, all_pages = TRUE, max_pages = 100) {
  params <- list("medium" = medium, "pageNumber" = pageNumber, "all_pages" = all_pages, "max_pages" = max_pages)
  result <- generic_request(
    "endpoint" = "exposure/mmdb/single-sample/by-medium",
    "method" = "GET",
    "batch_limit" = 0,
    "medium" = params[["medium"]],
    "pageNumber" = params[["pageNumber"]],
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "page_number"
  )
  result
}
