#' Get total assay count
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_count(query = "DTXSID7020182")
#' }
ct_bioactivity_assay_count <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/assay/count",
    method = "GET",
    batch_limit = 1
  )
}

