#' Get assay summary by gene symbol
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param geneSymbol Gene Symbol
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_by_gene(geneSymbol = "TUBA1A")
#' }
ct_bioactivity_assay_by_gene <- function(geneSymbol) {
  generic_request(
    query = geneSymbol,
    endpoint = "bioactivity/assay/search/by-gene/",
    method = "GET",
    batch_limit = 1
  )
}

