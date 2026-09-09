#' Get mol file by DTXCID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_file_mol_search_by_dtxcid(dtxcid = "DTXCID505")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_file_mol_search_by_dtxcid <- function(dtxcid) {
  params <- list("dtxcid" = dtxcid)
  result <- generic_request(
    "query" = params[["dtxcid"]],
    "endpoint" = "chemical/file/mol/search/by-dtxcid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
