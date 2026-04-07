#' Search by starting value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param value Starting characters for search value. Type: string
#' @param top Optional parameter (default: 500)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_search_start_with(value = "DTXSID7020182")
#' }
ct_bioactivity_search_start_with <- function(value, top = 500) {
  result <- generic_request(
    query = value,
    endpoint = "bioactivity/search/start-with/",
    method = "GET",
    batch_limit = 1,
    `top` = top
  )

  # Additional post-processing can be added here

  return(result)
}


