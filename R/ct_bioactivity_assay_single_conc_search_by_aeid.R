#' Get single conc data by AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid ToxCast assay component endpoint ID. Type: integer
#' @param projection Optional parameter (default: single-conc)
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_single_conc_search_by_aeid(aeid = "3032")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_single_conc_search_by_aeid <- function(aeid, projection = "single-conc") {
  params <- base::list("aeid" = aeid, "projection" = projection)
  result <- generic_request(
    "query" = params[["aeid"]],
    "endpoint" = "bioactivity/assay/single-conc/search/by-aeid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
