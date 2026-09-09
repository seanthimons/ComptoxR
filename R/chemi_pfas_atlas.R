#' Generate PFAS Atlas categories for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles SMILES string of the molecule
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_pfas_atlas(smiles = "O=C(O)C(F)(F)C(F)(F)C(F)(F)C(F)(F)F")
#' }
# Generated with apipak; do not edit by hand.
chemi_pfas_atlas <- function(smiles) {
  params <- list("smiles" = smiles)
  result <- generic_request(
    "endpoint" = "pfas_atlas",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("smiles" = params[["smiles"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}

#' Generate PFAS Atlas categories for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Either an array of input chemicals with optional id and required smiles, or an array of SMILES strings for backward compatibility.
#' @param smiles Array of SMILES strings, kept for backward compatibility with the previous PFAS Atlas POST format.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_pfas_atlas_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_pfas_atlas_bulk <- function(chemicals = NULL, smiles = NULL) {
  params <- list("chemicals" = chemicals, "smiles" = smiles)
  result <- generic_chemi_request(
    "query" = params[["chemicals"]],
    "endpoint" = "pfas_atlas",
    "options" = local({
      .body <- Filter(Negate(is.null), list("smiles" = params[["smiles"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
