#' Generate NCC categories for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles SMILES to generate NCC categories for
#' @param logp Octanol-water partition coefficient
#' @param ws Water solubility (mg/L)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_ncc_cats(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_ncc_cats <- function(smiles, logp = NULL, ws = NULL) {
  params <- list("smiles" = smiles, "logp" = logp, "ws" = ws)
  result <- generic_request(
    "endpoint" = "ncc_cats",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("smiles" = params[["smiles"]], "logp" = params[["logp"]], "ws" = params[["ws"]])
      )
      if (length(.body)) .body else list()
    })
  )
  result
}

#' Generate NCC categories for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Array of input chemicals with optional id, smiles, logp, and ws. Missing smiles are returned as item-level errors.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_ncc_cats_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_ncc_cats_bulk <- function(chemicals = NULL) {
  params <- list("chemicals" = chemicals)
  result <- generic_chemi_request(
    "query" = params[["chemicals"]],
    "endpoint" = "ncc_cats",
    "wrap" = FALSE,
    "tidy" = FALSE
  )
  result
}
