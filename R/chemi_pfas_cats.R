#' Generate PFAS categories for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_pfas_cats(smiles = "FC(C(C(C1OC(=O)C2C(=CC=CC=2)N=1)(F)F)(F)F)(F)F")
#' }
# Generated with specmill; do not edit by hand.
chemi_pfas_cats <- function(smiles) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles),
    list(smiles = list(type = "string")),
    .api_validation$body_value,
    c(smiles = "query")
  )
  params <- base::list("smiles" = smiles)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/pfas_cats",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
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
# Generated with specmill; do not edit by hand.
chemi_pfas_cats_bulk <- function(chemicals = NULL, smiles = NULL) {
  params <- base::list("chemicals" = chemicals, "smiles" = smiles)
  result <- generic_chemi_request(
    "query" = params[["chemicals"]],
    "endpoint" = "pfas_cats",
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("smiles" = params[["smiles"]]))
      if (base::length(.body)) .body else base::list()
    }),
    "tidy" = FALSE
  )
  result
}
