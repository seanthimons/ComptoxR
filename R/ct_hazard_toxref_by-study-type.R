#' Get summary data by Study Type
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
#' ct_hazard_toxref_by_study_type(query = "DTXSID7020182")
#' }
ct_hazard_toxref_by_study_type <- function(query) {
  generic_request(
    query = query,
    endpoint = "hazard/toxref/summary/search/by-study-type/",
    method = "GET",
		batch_limit = 1
  )
}

