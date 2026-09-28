#' Get MS-ready chemicals using mass range
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param start Starting mass value. Type: number
#' @param end Ending mass value. Type: number
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass(start = "200.9")
#' }
ct_chemical_msready_search_by_mass <- function(start, end = NULL) {
  result <- generic_request(
    query = start,
    endpoint = "chemical/msready/search/by-mass/",
    method = "GET",
    batch_limit = 1,
    path_params = c(end = end)
  )

  # Additional post-processing can be added here

  return(result)
}
