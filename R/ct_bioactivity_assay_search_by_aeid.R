#' Get assay annotations for a batch of AEIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_aeid_bulk()
#' }
ct_bioactivity_assay_search_by_aeid_bulk <- function() {
  # Build request body
  body <- list()

  result <- generic_request(
    query = NULL,
    endpoint = "bioactivity/assay/search/by-aeid/",
    method = "POST",
    batch_limit = NULL,
    body = body
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get assay annotations by AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param aeid ToxCast assay component endpoint ID. Type: integer
#' @param projection Specifies which projection to use. Options: ccd-assay-annotation, ccd-assay-gene, ccd-assay-citations, ccd-assay-tcpl, ccd-assay-reagents, assay-all. If omitted, the full assay data is returned.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_aeid(aeid = "3032")
#' }
ct_bioactivity_assay_search_by_aeid <- function(aeid, projection = NULL) {
  result <- generic_request(
    query = aeid,
    endpoint = "bioactivity/assay/search/by-aeid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


