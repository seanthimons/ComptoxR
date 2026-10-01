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
# Generated with specmill; do not edit by hand.
chemi_amnb_nate <- function(smiles) {
  params <- base::list("smiles" = smiles)
  result <- generic_request(
    "endpoint" = "amnb_nate",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("smiles" = params[["smiles"]]))
      if (base::length(.body)) .body else base::list()
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
# Generated with specmill; do not edit by hand.
chemi_amnb_nate_bulk <- function(chemicals = NULL, smiles = NULL) {
  params <- base::list("chemicals" = chemicals, "smiles" = smiles)
  result <- generic_chemi_request(
    "query" = params[["chemicals"]],
    "endpoint" = "amnb_nate",
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("smiles" = params[["smiles"]]))
      if (base::length(.body)) .body else base::list()
    }),
    "tidy" = FALSE
  )
  result
}
