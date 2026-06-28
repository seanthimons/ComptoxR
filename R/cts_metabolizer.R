#' Transformation pathways predictions.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' cts_metabolizer()
#' }
cts_metabolizer <- function() {
  result <- generic_cts_request(
    endpoint = "metabolizer",
    method = "GET",
    body = list(),
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
