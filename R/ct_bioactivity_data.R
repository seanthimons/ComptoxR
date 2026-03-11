#' Get bioactivity data for a batch of DTXSIDs
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
#' ct_bioactivity_data_bulk(query = "DTXSID7020182")
#' }
ct_bioactivity_data_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "bioactivity/data/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Specifies if projection is used. Option: toxcast-summary-plot. If omitted, the default BioactivityDataAll data is returned.
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data(dtxsid = "DTXSID7020182")
#' }
ct_bioactivity_data <- function(dtxsid, projection = NULL) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "bioactivity/data/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get summary data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data(dtxsid = "DTXSID9026974")
#' }
ct_bioactivity_data <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "bioactivity/data/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


