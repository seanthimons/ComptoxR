#' Get AOP data by ToxCast AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param toxcastAeid ToxCast AEID. Type: integer
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_toxcast_aeid(toxcastAeid = "63")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_aop_search_by_toxcast_aeid <- function(toxcastAeid) {
  params <- base::list("toxcastAeid" = toxcastAeid)
  result <- generic_request(
    "query" = params[["toxcastAeid"]],
    "endpoint" = "bioactivity/aop/search/by-toxcast-aeid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
