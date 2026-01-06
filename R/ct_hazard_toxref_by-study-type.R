#' Get summary data by Study Type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param studyType Study Type
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_by_study_type(studyType = "DEV")
#' }
ct_hazard_toxref_by_study_type <- function(studyType) {
  generic_request(
    query = studyType,
    endpoint = "hazard/toxref/summary/search/by-study-type/",
    method = "GET",
    batch_limit = 1
  )
}

