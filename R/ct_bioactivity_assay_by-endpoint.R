#' Get AEID by assay component endpoint name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param endpoint Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_by_endpoint(query = "DTXSID7020182")
#' }
ct_bioactivity_assay_by_endpoint <- function(query, endpoint = NULL) {
  generic_request(
    query = query,
    endpoint = "bioactivity/assay/search/by-endpoint/",
    method = "GET",
    batch_limit = 1,
    endpoint = endpoint
  )
}

