#' Generate an ARN category for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles SMILES to generate groups for
#' @param model Model to use for group prediction. Options: RF, NN (default: RF)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_arn_cats(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_arn_cats <- function(smiles, model = "RF") {
  params <- list("smiles" = smiles, "model" = model)
  result <- generic_request(
    "endpoint" = "arn_cats",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("smiles" = params[["smiles"]], "model" = params[["model"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}

#' Generate groups for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Array of objects with optional id and smiles, or an array of SMILES strings for backward compatibility.
#' @param model Optional parameter. Options: RF, NN (default: RF)
#' @param smiles Array of SMILES strings, same input style as amnb_nate.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_arn_cats_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_arn_cats_bulk <- function(chemicals = NULL, model = "RF", smiles = NULL) {
  params <- list("chemicals" = chemicals, "model" = model, "smiles" = smiles)
  result <- generic_chemi_request(
    "query" = params[["chemicals"]],
    "endpoint" = "arn_cats",
    "options" = local({
      .body <- Filter(Negate(is.null), list("model" = params[["model"]], "smiles" = params[["smiles"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
