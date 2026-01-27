#' Get AOP data by ToxCast AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param toxcastAeid ToxCast AEID. Type: integer
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_toxcast_aeid(toxcastAeid = "63")
#' }
ct_bioactivity_aop_search_by_toxcast_aeid <- function(toxcastAeid) {
  result <- generic_request(
    query = toxcastAeid,
    endpoint = "bioactivity/aop/search/by-toxcast-aeid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


