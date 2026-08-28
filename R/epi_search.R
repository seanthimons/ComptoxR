#' Search embedded experimental data
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param limit Optional parameter (default: 20)
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_search(query = "benzene")
#' }
epi_search <- function(query, limit = 20) {
  result <- generic_request(
    endpoint = "search",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    query_params = list(
    `query` = query,
    `limit` = limit
    )
  )

    result <- run_hook("epi_search", "post_response", list(result = result, params = list(`query` = query, `limit` = limit)))
# Additional post-processing can be added here

  return(result)
}


