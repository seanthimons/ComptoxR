#' Get assay annotations for a batch of AEIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_by_aeid(query = "DTXSID7020182")
#' }
ct_bioactivity_assay_by_aeid <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/assay/search/by-aeid/",
    method = "POST",
		batch_limit = NA
  )
}

