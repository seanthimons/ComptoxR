#' Amnb Nate
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles SMILES to generate predictions for
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amnb_nate(smiles = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_amnb_nate <- function(smiles) {
  params <- list("smiles" = smiles)
  result <- generic_request(
    "endpoint" = "amnb_nate",
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

#' Generate predictions for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Optional parameter
#' @param smiles Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amnb_nate_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amnb_nate_bulk <- function(chemicals = NULL, smiles = NULL) {
  params <- list("chemicals" = chemicals, "smiles" = smiles)
  result <- generic_chemi_request(
    "query" = params[["chemicals"]],
    "endpoint" = "amnb_nate",
    "options" = local({
      .body <- Filter(Negate(is.null), list("smiles" = params[["smiles"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
