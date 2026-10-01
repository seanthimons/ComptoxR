#' Get AEID by assay component endpoint name
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param endpoint Required parameter
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_endpoint(endpoint = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_search_by_endpoint <- function(endpoint) {
  params <- base::list("endpoint" = endpoint)
  result <- generic_request(
    "endpoint" = "bioactivity/assay/search/by-endpoint/",
    "method" = "GET",
    "batch_limit" = 0,
    "query_params" = base::list("endpoint" = params[["endpoint"]])
  )
  result
}
