#' Get Single Sample data by DTXSID
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
#' ct_exposure_mmdb_single_sample(query = "DTXSID7020182")
#' }
ct_exposure_mmdb_single_sample <- function(query) {
  generic_request(
    query = query,
    endpoint = "exposure/mmdb/single-sample/by-dtxsid/",
    method = "GET",
		batch_limit = 1
  )
}

