#' Opera
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles SMILES to generate predictions for
#' @param format Format to return predictions in (json, csv, xlsx) (default: json)
#' @param standardize Standardize chemical before calculating predictions (default: FALSE)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_opera(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_opera <- function(smiles, format = "json", standardize = FALSE) {
  params <- base::list("smiles" = smiles, "format" = format, "standardize" = standardize)
  result <- generic_request(
    "endpoint" = "opera",
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
          "format" = params[["format"]],
          "standardize" = params[["standardize"]]
        )
      )
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
