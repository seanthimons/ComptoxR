#' Get MS-ready chemicals for a batch of mass ranges
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
#' ct_chemical_msready_by_mass(query = "DTXSID7020182")
#' }
ct_chemical_msready_by_mass <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/msready/search/by-mass/",
    method = "POST",
		batch_limit = NA
  )
}

