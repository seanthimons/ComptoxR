#' Get observations by Study ID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxref_observations_by_study_id(query = "DTXSID7020182")
#' }
ct_hazard_toxref_observations_by_study_id <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/toxref/observations/search/by-study-id/",
    method = "GET",
		batch_limit = 1
  )
}

