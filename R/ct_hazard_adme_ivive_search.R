#' Get ADME data for IVIVE by DTXSID with CCD projection
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies if projection is used. Option: ccd-adme-data. If omitted, the default ADME-IVIVE projection is returned.
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_adme_ivive_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_adme_ivive_search <- function(dtxsid, projection = NULL) {
  params <- base::list("dtxsid" = dtxsid, "projection" = projection)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "hazard/adme-ivive/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
