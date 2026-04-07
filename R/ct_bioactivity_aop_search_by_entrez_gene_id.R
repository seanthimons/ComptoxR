#' Get AOP data by Entrez Gene ID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param entrezGeneId Entrez Gene Id. Type: integer
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_entrez_gene_id(entrezGeneId = "196")
#' }
ct_bioactivity_aop_search_by_entrez_gene_id <- function(entrezGeneId) {
  result <- generic_request(
    query = entrezGeneId,
    endpoint = "bioactivity/aop/search/by-entrez-gene-id/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


