#' Get mol file by DTXCID
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
#' ct_chemical_file_mol_by_dtxcid(query = "DTXSID7020182")
#' }
ct_chemical_file_mol_by_dtxcid <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/file/mol/search/by-dtxcid/",
    method = "GET",
		batch_limit = 1
  )
}

