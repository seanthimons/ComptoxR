#' Get ADME data for IVIVE by DTXSID with CCD projection
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies if projection is used. Option: ccd-adme-data. If omitted, the default ADME-IVIVE projection is returned.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_adme_ivive_search(dtxsid = "DTXSID7020182")
#' }
ct_hazard_adme_ivive_search <- function(dtxsid, projection = NULL) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "hazard/adme-ivive/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


