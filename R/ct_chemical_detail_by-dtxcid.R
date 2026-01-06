#' Get data for a batch of DTXCIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param projection Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_by_dtxcid(query = "DTXSID7020182")
#' }
ct_chemical_detail_by_dtxcid <- function(query, projection = NULL) {
  generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxcid/",
    method = "POST",
    batch_limit = NULL,
    projection = projection
  )
}

