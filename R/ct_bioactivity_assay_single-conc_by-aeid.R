#' Get single conc data by AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param aeid ToxCast assay component endpoint ID. Type: integer
#' @param projection Optional parameter (default: single-conc)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_single_conc_by_aeid(aeid = "3032")
#' }
ct_bioactivity_assay_single_conc_by_aeid <- function(aeid, projection = "single-conc") {
  result <- generic_request(
    query = aeid,
    endpoint = "bioactivity/assay/single-conc/search/by-aeid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


