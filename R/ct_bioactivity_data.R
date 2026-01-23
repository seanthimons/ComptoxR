#' Get bioactivity data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data(query = "DTXSID7020182")
#' }
ct_bioactivity_data <- function(query) {
  generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-dtxsid/",
    method = "POST",
    batch_limit = NULL
  )
}

#' Get summary data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data()
#' }
ct_bioactivity_data <- function() {
  result <- generic_request(
    endpoint = "bioactivity/data/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


