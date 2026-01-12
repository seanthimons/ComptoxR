#' Get data for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_extra_data(query = "DTXSID7020182")
#' }
ct_chemical_extra_data <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/extra-data/search/by-dtxsid/",
    method = "POST",
    batch_limit = NULL
  )
}

