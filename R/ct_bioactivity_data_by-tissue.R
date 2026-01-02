#' Get summary data by DTXSID and assay tissue origin
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param tissue Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_data_by_tissue(query = "DTXSID7020182")
#' }
ct_bioactivity_data_by_tissue <- function(query, tissue = NULL) {
  # Collect optional parameters
  extra_params <- list()
  if (!is.null(tissue)) extra_params$tissue <- tissue

  do.call(
    generic_request,
    c(
      list(
        query = query,
        endpoint = "bioactivity/data/summary/search/by-tissue/",
        method = "GET",
		batch_limit = 1
      ),
      extra_params
    )
  )
}