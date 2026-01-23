#' Get fate summary by DTXSID and property
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Optional parameter
#' @param propName Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_fate(query = "DTXSID7020182")
#' }
ct_chemical_fate <- function(query, dtxsid = NULL, propName = NULL) {
  generic_request(
    query = query,
    endpoint = "chemical/fate/summary/search/",
    method = "GET",
    batch_limit = 1,
    dtxsid = dtxsid,
    propName = propName
  )
}

#' Get fate data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_fate()
#' }
ct_chemical_fate <- function() {
  result <- generic_request(
    endpoint = "chemical/fate/search/by-dtxsid/",
    method = "POST",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get fate summary by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_fate()
#' }
ct_chemical_fate <- function() {
  result <- generic_request(
    endpoint = "chemical/fate/summary/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


