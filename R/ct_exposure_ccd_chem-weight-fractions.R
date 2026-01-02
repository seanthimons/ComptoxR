#' Get Chemical Weight Fractions data by DTXSID
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
#' ct_exposure_ccd_chem_weight_fractions(query = "DTXSID7020182")
#' }
ct_exposure_ccd_chem_weight_fractions <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/ccd/chem-weight-fractions/search/by-dtxsid/",
    method = "GET",
		batch_limit = 1
  )
}

