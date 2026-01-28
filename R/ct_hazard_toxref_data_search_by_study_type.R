#' Get all data by Study Type
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param studyType Study Type. Type: string
#' @param pageNumber Optional parameter (default: 1)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_data_search_by_study_type(studyType = "DEV")
#' }
ct_hazard_toxref_data_search_by_study_type <- function(studyType, pageNumber = 1) {
  result <- generic_request(
    query = studyType,
    endpoint = "hazard/toxref/data/search/by-study-type/",
    method = "GET",
    batch_limit = 1,
    `pageNumber` = pageNumber
  )

  # Additional post-processing can be added here

  return(result)
}


