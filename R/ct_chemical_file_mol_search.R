#' Get mol file by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_file_mol_search(dtxsid = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_file_mol_search <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "chemical/file/mol/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
