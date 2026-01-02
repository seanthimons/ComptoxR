#' Get AOP data by ToxCast AEID
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
#' ct_bioactivity_aop_by_toxcast_aeid(query = "DTXSID7020182")
#' }
ct_bioactivity_aop_by_toxcast_aeid <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/aop/search/by-toxcast-aeid/",
    method = "GET",
		batch_limit = 1
  )
}

