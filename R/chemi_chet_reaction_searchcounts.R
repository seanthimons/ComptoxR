#' Count search results
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param search_input Primary query parameter. Type: string
#' @param search_type Optional parameter. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_searchcounts(search_input = "DTXSID7020182")
#' }
chemi_chet_reaction_searchcounts <- function(search_input, search_type = NULL) {
  result <- generic_request(
    query = search_input,
    endpoint = "reaction/searchcounts/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(search_type = search_type)
  )

  # Additional post-processing can be added here

  return(result)
}


