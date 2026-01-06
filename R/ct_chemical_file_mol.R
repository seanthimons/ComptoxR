#' Get mol file by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_mol(dtxsid = "DTXSID7020182")
#' }
ct_chemical_file_mol <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "chemical/file/mol/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )
}

