#' Get assay summary by gene symbol
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
#' ct_bioactivity_assay_by_gene(query = "DTXSID7020182")
#' }
ct_bioactivity_assay_by_gene <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/assay/search/by-gene/",
    method = "GET",
		batch_limit = 1
  )
}

