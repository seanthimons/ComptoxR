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
  params <- list("smiles" = smiles, "exportSmiles" = exportSmiles, "exportMol" = exportMol)
  result <- generic_request(
    "endpoint" = "search/substructure",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "smiles" = params[["smiles"]],
          "exportSmiles" = params[["exportSmiles"]],
          "exportMol" = params[["exportMol"]]
        )
      )
      if (length(.body)) .body else list()
    })
  )
  result
}
