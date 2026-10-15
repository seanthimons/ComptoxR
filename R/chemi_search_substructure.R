#' Search Substructure
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles Required parameter
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_search_substructure(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_search_substructure <- function(smiles, exportSmiles = NULL, exportMol = NULL) {
  params <- base::list("smiles" = smiles, "exportSmiles" = exportSmiles, "exportMol" = exportMol)
  result <- generic_request(
    "endpoint" = "search/substructure",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list(
          "smiles" = params[["smiles"]],
          "exportSmiles" = params[["exportSmiles"]],
          "exportMol" = params[["exportMol"]]
        )
      )
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
