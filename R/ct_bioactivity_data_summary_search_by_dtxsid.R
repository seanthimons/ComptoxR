#' Get summary data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_summary_search_by_dtxsid(dtxsid = "DTXSID9026974")
#' }
ct_bioactivity_data_summary_search_by_dtxsid <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "bioactivity/data/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}
