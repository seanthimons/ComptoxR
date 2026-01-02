#' Get single conc data by AEID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param projection Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_single_conc_by_aeid(query = "DTXSID7020182")
#' }
ct_bioactivity_assay_single_conc_by_aeid <- function(query, projection = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(projection)) extra_params$projection <- projection

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "bioactivity/assay/single-conc/search/by-aeid/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}