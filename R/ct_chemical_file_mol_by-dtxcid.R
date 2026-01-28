#' Get mol file by DTXCID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_mol_by_dtxcid(dtxcid = "DTXCID505")
#' }
ct_chemical_file_mol_by_dtxcid <- function(dtxcid) {
  result <- generic_request(
    query = dtxcid,
    endpoint = "chemical/file/mol/search/by-dtxcid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


