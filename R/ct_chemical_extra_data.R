#' Get data for a batch of DTXSIDs
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
#' ct_chemical_extra_data_bulk(query = "DTXSID7020182")
#' }
ct_chemical_extra_data_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/extra-data/search/by-dtxsid/",
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
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_extra_data(dtxsid = "DTXSID101296374")
#' }
ct_chemical_extra_data <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "chemical/extra-data/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


