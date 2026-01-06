#' Get AOP data by ToxCast AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param toxcastAeid ToxCast AEID
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_by_toxcast_aeid(toxcastAeid = "63")
#' }
ct_bioactivity_aop_by_toxcast_aeid <- function(toxcastAeid) {
  generic_request(
    query = toxcastAeid,
    endpoint = "bioactivity/aop/search/by-toxcast-aeid/",
    method = "GET",
    batch_limit = 1
  )
}

