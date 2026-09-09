#' Search Similar
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles Optional parameter
#' @param dtxsid Optional parameter
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter
#' @param min Optional parameter
#' @param max Optional parameter
#' @param similarityType Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_search_similar(smiles = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_search_similar <- function(
  smiles = NULL,
  dtxsid = NULL,
  exportSmiles = NULL,
  exportMol = NULL,
  min = NULL,
  max = NULL,
  similarityType = NULL
) {
  params <- list(
    "smiles" = smiles,
    "dtxsid" = dtxsid,
    "exportSmiles" = exportSmiles,
    "exportMol" = exportMol,
    "min" = min,
    "max" = max,
    "similarityType" = similarityType
  )
  result <- generic_request(
    "endpoint" = "search/similar",
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
          "dtxsid" = params[["dtxsid"]],
          "exportSmiles" = params[["exportSmiles"]],
          "exportMol" = params[["exportMol"]],
          "min" = params[["min"]],
          "max" = params[["max"]],
          "similarityType" = params[["similarityType"]]
        )
      )
      if (length(.body)) .body else list()
    })
  )
  result
}
