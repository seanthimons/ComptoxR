#' Search by substring value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param value Substring of search word. Type: string
#' @param top Optional parameter (default: 0)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_search_contain(value = "DTXSID7020182")
#' }
ct_bioactivity_search_contain <- function(value, top = 0) {
  result <- generic_request(
    query = value,
    endpoint = "bioactivity/search/contain/",
    method = "GET",
    batch_limit = 1,
    `top` = top
  )

  # Additional post-processing can be added here

  return(result)
}


