#' Get summary data by Study Type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param studyType Study Type. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_search_by_study_type(studyType = "DEV")
#' }
ct_hazard_toxref_search_by_study_type <- function(studyType) {
  result <- generic_request(
    query = studyType,
    endpoint = "hazard/toxref/summary/search/by-study-type/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


