#' Get summary data by AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param aeid ToxCast assay component endpoint ID (AEID). Type: integer
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_summary_search_by_aeid(aeid = "3032")
#' }
ct_bioactivity_data_summary_search_by_aeid <- function(aeid) {
  result <- generic_request(
    query = aeid,
    endpoint = "bioactivity/data/summary/search/by-aeid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}
