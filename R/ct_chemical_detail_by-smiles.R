#' Get data by SMILES
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
#' ct_chemical_detail_by_smiles(query = "DTXSID7020182")
#' }
ct_chemical_detail_by_smiles <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-smiles/",
    method = "GET",
		batch_limit = 1
  )
}

