#' Get AOP data by Entrez Gene ID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param entrezGeneId Entrez Gene Id. Type: integer
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_entrez_gene_id(entrezGeneId = "196")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_aop_search_by_entrez_gene_id <- function(entrezGeneId) {
  params <- base::list("entrezGeneId" = entrezGeneId)
  result <- generic_request(
    "query" = params[["entrezGeneId"]],
    "endpoint" = "bioactivity/aop/search/by-entrez-gene-id/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
