#' Get AOP data by Key Event
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param eventNumber Key Event Number
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_by_event_number(eventNumber = "18")
#' }
ct_bioactivity_aop_by_event_number <- function(eventNumber) {
  generic_request(
    query = eventNumber,
    endpoint = "bioactivity/aop/search/by-event-number/",
    method = "GET",
    batch_limit = 1
  )
}

