#' Get data for a batch of M4IDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id_bulk()
#' }
ct_bioactivity_data_search_by_m4id_bulk <- function() {
  # Build request body
  body <- list()

  result <- generic_request(
    query = NULL,
    endpoint = "bioactivity/data/search/by-m4id/",
    method = "POST",
    batch_limit = NULL,
    body = body
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get data by M4ID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param m4id M4ID. Type: integer
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_search_by_m4id(m4id = "7826737")
#' }
ct_bioactivity_data_search_by_m4id <- function(m4id) {
  result <- generic_request(
    query = m4id,
    endpoint = "bioactivity/data/search/by-m4id/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


