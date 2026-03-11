#' Get all data by dtxsid and category
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param category Required parameter
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxval_by_category(dtxsid = "DTXSID0021125")
#' }
ct_hazard_toxval_by_category <- function(dtxsid, category) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "hazard/toxval/search/by-category/",
    method = "GET",
    batch_limit = 1,
    `category` = category
  )

  # Additional post-processing can be added here

  return(result)
}


