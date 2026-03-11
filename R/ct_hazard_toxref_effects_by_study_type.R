#' Get effects data by Study Type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param studyType Study Type. Type: string
#' @param pageNumber Optional parameter (default: 1)
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_effects_by_study_type(studyType = "DEV")
#' }
ct_hazard_toxref_effects_by_study_type <- function(studyType, pageNumber = 1, all_pages = TRUE) {
  result <- generic_request(
    query = studyType,
    endpoint = "hazard/toxref/effects/search/by-study-type/",
    method = "GET",
    batch_limit = 1,
    `pageNumber` = pageNumber,
    paginate = all_pages,
    max_pages = 100,
    pagination_strategy = "page_number"
  )

  # Additional post-processing can be added here

  return(result)
}


