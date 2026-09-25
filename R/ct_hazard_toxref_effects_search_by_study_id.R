#' Get effects data by Study ID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param studyId Study ID. Type: integer
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_effects_search_by_study_id(studyId = "63")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_effects_search_by_study_id <- function(studyId) {
  params <- base::list("studyId" = studyId)
  result <- generic_request(
    "query" = params[["studyId"]],
    "endpoint" = "hazard/toxref/effects/search/by-study-id/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
