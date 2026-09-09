#' Get Chemical Weight Fractions data by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_exposure_ccd_chem_weight_fractions_search(dtxsid = "DTXSID0020232")
#' }
# Generated with apipak; do not edit by hand.
ct_exposure_ccd_chem_weight_fractions_search <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "exposure/ccd/chem-weight-fractions/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
