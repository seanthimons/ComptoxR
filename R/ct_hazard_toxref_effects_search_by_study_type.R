#' Get effects data by Study Type
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param studyType Study Type. Type: string
#' @param pageNumber Optional parameter (default: 1)
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_effects_search_by_study_type(studyType = "DEV")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_effects_search_by_study_type <- function(studyType, pageNumber = 1, all_pages = TRUE) {
  params <- base::list("studyType" = studyType, "pageNumber" = pageNumber, "all_pages" = all_pages)
  result <- generic_request(
    "query" = params[["studyType"]],
    "endpoint" = "hazard/toxref/effects/search/by-study-type/",
    "method" = "GET",
    "batch_limit" = 1,
    "pageNumber" = params[["pageNumber"]],
    "paginate" = params[["all_pages"]],
    "max_pages" = 100,
    "pagination_strategy" = "page_number"
  )
  result
}
