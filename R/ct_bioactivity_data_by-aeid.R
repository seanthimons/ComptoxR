#' Get data for a batch of AEIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_by_aeid(query = "DTXSID7020182")
#' }
ct_bioactivity_data_by_aeid <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-aeid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get summary data by AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param aeid ToxCast assay component endpoint ID (AEID). Type: integer
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_by_aeid(aeid = "3032")
#' }
ct_bioactivity_data_by_aeid <- function(aeid) {
  result <- generic_request(
    query = aeid,
    endpoint = "bioactivity/data/summary/search/by-aeid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


