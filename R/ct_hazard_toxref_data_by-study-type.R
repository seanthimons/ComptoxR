#' Get all data by Study Type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param studyType Study Type
#' @param pageNumber Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_data_by_study_type(studyType = "DEV")
#' }
ct_hazard_toxref_data_by_study_type <- function(studyType, pageNumber = NULL) {
  generic_request(
    query = studyType,
    endpoint = "hazard/toxref/data/search/by-study-type/",
    method = "GET",
    batch_limit = 1,
    pageNumber = pageNumber
  )
}

