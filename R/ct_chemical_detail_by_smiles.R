#' Get data by SMILES
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES String
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_detail_by_smiles(smiles = "CC(C)(C1=CC=C(O)C=C1)C1=CC=C(O)C=C1")
#' }
ct_chemical_detail_by_smiles <- function(smiles) {
  result <- generic_request(
    endpoint = "chemical/detail/search/by-smiles/",
    method = "GET",
    batch_limit = 0,
    `smiles` = smiles
  )

  # Additional post-processing can be added here

  return(result)
}


