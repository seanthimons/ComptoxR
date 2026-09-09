#' Generate PFAS categories for one molecule
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
#' chemi_pfas_cats(smiles = "FC(C(C(C1OC(=O)C2C(=CC=CC=2)N=1)(F)F)(F)F)(F)F")
#' }
# Generated with apipak; do not edit by hand.
chemi_pfas_cats <- function(smiles) {
  params <- list("smiles" = smiles)
  result <- generic_request(
    "endpoint" = "pfas_cats",
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

#' Generate PFAS categories for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Either an array of input chemicals with optional id and required smiles, or an array of SMILES strings for backward compatibility.
#' @param smiles Array of SMILES strings, kept for backward compatibility with the previous PFAS Cats POST format.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_pfas_cats_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_pfas_cats_bulk <- function(chemicals = NULL, smiles = NULL) {
  params <- list("chemicals" = chemicals, "smiles" = smiles)
  result <- generic_chemi_request(
    "query" = params[["chemicals"]],
    "endpoint" = "pfas_cats",
    "options" = local({
      .body <- Filter(Negate(is.null), list("smiles" = params[["smiles"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
