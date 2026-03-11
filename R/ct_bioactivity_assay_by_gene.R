#' Get assay summary by gene symbol
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param geneSymbol Gene Symbol. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_by_gene(geneSymbol = "TUBA1A")
#' }
ct_bioactivity_assay_by_gene <- function(geneSymbol) {
  result <- generic_request(
    query = geneSymbol,
    endpoint = "bioactivity/assay/search/by-gene/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


