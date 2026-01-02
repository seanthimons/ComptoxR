#' Get MS-ready chemicals for a batch of DTXCIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_msready_by_dtxcid(query = "DTXSID7020182")
#' }
ct_chemical_msready_by_dtxcid <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/msready/search/by-dtxcid/",
    method = "POST",
		batch_limit = NA
  )
}

