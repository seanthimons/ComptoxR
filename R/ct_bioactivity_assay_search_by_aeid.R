#' Get assay annotations for a batch of AEIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_aeid_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_search_by_aeid_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "bioactivity/assay/search/by-aeid/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get assay annotations by AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param aeid ToxCast assay component endpoint ID. Type: integer
#' @param projection Specifies which projection to use. Options: ccd-assay-annotation, ccd-assay-gene, ccd-assay-citations, ccd-assay-tcpl, ccd-assay-reagents, assay-all. If omitted, the full assay data is returned.
#' @return Returns a scalar value
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_aeid(aeid = "3032")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_search_by_aeid <- function(aeid, projection = NULL) {
  params <- base::list("aeid" = aeid, "projection" = projection)
  result <- generic_request(
    "query" = params[["aeid"]],
    "endpoint" = "bioactivity/assay/search/by-aeid/",
    "method" = "GET",
    "batch_limit" = 1,
    "projection" = params[["projection"]]
  )
  result
}
