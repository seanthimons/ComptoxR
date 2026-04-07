#' Get summary data by DTXSID and assay tissue origin
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier
#' @param tissue assay format's tissue of origin
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_tissue(dtxsid = "DTXSID7024241")
#' }
ct_bioactivity_data_search_by_tissue <- function(dtxsid, tissue) {
  result <- generic_request(
    endpoint = "bioactivity/data/summary/search/by-tissue/",
    method = "GET",
    batch_limit = 0,
    `dtxsid` = dtxsid,
    `tissue` = tissue
  )

  # Additional post-processing can be added here

  return(result)
}


