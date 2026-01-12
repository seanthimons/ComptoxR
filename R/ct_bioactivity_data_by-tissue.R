#' Get summary data by DTXSID and assay tissue origin
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier
#' @param tissue assay format's tissue of origin
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_by_tissue(query = "DTXSID7020182")
#' }
ct_bioactivity_data_by_tissue <- function(query, dtxsid = NULL, tissue = NULL) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/summary/search/by-tissue/",
    method = "GET",
    batch_limit = 1,
    dtxsid = dtxsid,
    tissue = tissue
  )
}

