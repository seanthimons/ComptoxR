#' Get summary data by Study ID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param studyId Study ID. Type: integer
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_by_study_id(studyId = "63")
#' }
ct_hazard_toxref_by_study_id <- function(studyId) {
  result <- generic_request(
    query = studyId,
    endpoint = "hazard/toxref/summary/search/by-study-id/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


