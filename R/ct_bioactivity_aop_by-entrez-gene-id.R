#' Get AOP data by Entrez Gene ID
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
#' ct_bioactivity_aop_by_entrez_gene_id(query = "DTXSID7020182")
#' }
ct_bioactivity_aop_by_entrez_gene_id <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/aop/search/by-entrez-gene-id/",
    method = "GET",
		batch_limit = 1
  )
}

