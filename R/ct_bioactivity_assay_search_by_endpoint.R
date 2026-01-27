#' Get AEID by assay component endpoint name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param endpoint Required parameter
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_endpoint(endpoint = "DTXSID7020182")
#' }
ct_bioactivity_assay_search_by_endpoint <- function(endpoint) {
  result <- generic_request(
    endpoint = "bioactivity/assay/search/by-endpoint/",
    method = "GET",
    batch_limit = 0,
    `endpoint` = endpoint
  )

  # Additional post-processing can be added here

  return(result)
}


