#' Get data by SMILES
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES String
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_by_smiles(query = "DTXSID7020182")
#' }
ct_chemical_detail_by_smiles <- function(query, smiles = NULL) {
  generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-smiles/",
    method = "GET",
    batch_limit = 1,
    smiles = smiles
  )
}

