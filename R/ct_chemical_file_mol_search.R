#' Get mol file by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_mol_search(dtxsid = "DTXSID7020182")
#' }
ct_chemical_file_mol_search <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "chemical/file/mol/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


