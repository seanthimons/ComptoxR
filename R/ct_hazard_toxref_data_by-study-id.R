#' Get all data by Study ID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param studyId Study ID
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_data_by_study_id(studyId = "63")
#' }
ct_hazard_toxref_data_by_study_id <- function(studyId) {
  generic_request(
    query = studyId,
    endpoint = "hazard/toxref/data/search/by-study-id/",
    method = "GET",
    batch_limit = 1
  )
}

