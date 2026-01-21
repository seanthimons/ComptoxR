#' Returns a list of similar substances to a given DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substance_similarity()
#' }
chemi_amos_substance_similarity <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/substance_similarity_search/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


