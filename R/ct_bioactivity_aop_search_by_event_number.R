#' Get AOP data by Key Event
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param eventNumber Key Event Number. Type: integer
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_event_number(eventNumber = "18")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_aop_search_by_event_number <- function(eventNumber) {
  params <- base::list("eventNumber" = eventNumber)
  result <- generic_request(
    "query" = params[["eventNumber"]],
    "endpoint" = "bioactivity/aop/search/by-event-number/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
