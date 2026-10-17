#' Get summary data by Study Type
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param studyType Study Type. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_search_by_study_type(studyType = "DEV")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_search_by_study_type <- function(studyType) {
  params <- base::list("studyType" = studyType)
  result <- generic_request(
    "query" = params[["studyType"]],
    "endpoint" = "hazard/toxref/summary/search/by-study-type/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
