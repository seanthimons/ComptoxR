#' Get assay summary by gene symbol
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param geneSymbol Gene Symbol. Type: string
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_gene(geneSymbol = "TUBA1A")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_search_by_gene <- function(geneSymbol) {
  params <- base::list("geneSymbol" = geneSymbol)
  result <- generic_request(
    "query" = params[["geneSymbol"]],
    "endpoint" = "bioactivity/assay/search/by-gene/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
