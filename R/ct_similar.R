#' @title Get Similar Compounds by DTXSID
#' 
#' @description
#' `r lifecycle::badge("questioning")`
#' 
#' @param query A character vector of DTXSIDs.
#' @param similarity The similarity threshold, a numeric value between 0 and 1. Optional, defaults to 0.8.
#'
#' @returns A tibble of similar compounds, or an empty tibble if no similar compounds are found.
#' @export
#'
#' @examples
#' \dontrun{
#' ct_similar(query = "DTXSID7020182", similarity = 0.8)
#' }
ct_similar <- function(query, similarity = 0.8) {
  
  if (similarity < 0 || similarity > 1) {
    cli::cli_abort("Similarity threshold must be between 0 and 1.")
  }

  if(!is.numeric(similarity)) {
    cli::cli_abort("Similarity threshold must be a numeric value.")
  }

  generic_request(
    query = query,
    endpoint = "similar-compound/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    server = "https://comptox.epa.gov/dashboard-api/",
    similarity
  )
}
