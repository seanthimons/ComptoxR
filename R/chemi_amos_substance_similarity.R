#' Returns a list of similar substances to a given DTXSID.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_substance_similarity(dtxsid = "DTXSID7020182")
#' }
chemi_amos_substance_similarity <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "amos/substance_similarity_search/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


