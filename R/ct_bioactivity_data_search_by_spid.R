#' Get data for a batch of SPIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid_bulk()
#' }
ct_bioactivity_data_search_by_spid_bulk <- function() {
  # Build request body
  body <- list()

  result <- generic_request(
    query = NULL,
    endpoint = "bioactivity/data/search/by-spid/",
    method = "POST",
    batch_limit = NULL,
    body = body
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get data by SPID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param spid sample ID (SPID). Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_spid(spid = "EPAPLT0232A03")
#' }
ct_bioactivity_data_search_by_spid <- function(spid) {
  result <- generic_request(
    query = spid,
    endpoint = "bioactivity/data/search/by-spid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


