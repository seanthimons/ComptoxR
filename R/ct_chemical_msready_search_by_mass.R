#' Get MS-ready chemicals for a batch of mass ranges
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param masses Required parameter
#' @param error Required parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass_bulk(masses = c("DTXSID40401774", "DTXSID70198443", "DTXSID901027719"))
#' }
ct_chemical_msready_search_by_mass_bulk <- function(masses, error) {
  # Build request body
  body <- list()
  body$masses <- masses
  body$error <- error

  result <- generic_request(
    query = NULL,
    endpoint = "chemical/msready/search/by-mass/",
    method = "POST",
    batch_limit = NULL,
    body = body
  )

  # Additional post-processing can be added here

  return(result)
}


#' Get MS-ready chemicals using mass range
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param start Starting mass value. Type: number
#' @param end Ending mass value. Type: number
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_search_by_mass(start = "200.9")
#' }
ct_chemical_msready_search_by_mass <- function(start, end = NULL) {
  result <- generic_request(
    query = start,
    endpoint = "chemical/msready/search/by-mass/",
    method = "GET",
    batch_limit = 1,
    path_params = c(end = end)
  )

  # Additional post-processing can be added here

  return(result)
}


