#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags(query = "DTXSID7020182")
#' }
chemi_resolver_safety_flags <- function(query, idType = "AnyId") {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) {
    options[['query']] <- query
  }
  if (!is.null(idType)) {
    options[['idType']] <- idType
  }
  result <- generic_request(
    endpoint = "resolver/safety-flags",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param averageMass Optional parameter
#' @param canonicalSmiles Optional parameter
#' @param casrn Optional parameter
#' @param chemId Optional parameter
#' @param cid Optional parameter
#' @param image Optional parameter
#' @param inchi Optional parameter
#' @param inchiKey Optional parameter
#' @param mol Optional parameter
#' @param molFormula Optional parameter
#' @param monoisotopicMass Optional parameter
#' @param name Optional parameter
#' @param sid Optional parameter
#' @param smiles Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags_bulk(averageMass = "DTXSID1024122")
#' }
chemi_resolver_safety_flags_bulk <- function(
  averageMass = NULL,
  canonicalSmiles = NULL,
  casrn = NULL,
  chemId = NULL,
  cid = NULL,
  image = NULL,
  inchi = NULL,
  inchiKey = NULL,
  mol = NULL,
  molFormula = NULL,
  monoisotopicMass = NULL,
  name = NULL,
  sid = NULL,
  smiles = NULL
) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(canonicalSmiles)) {
    options$canonicalSmiles <- canonicalSmiles
  }
  if (!is.null(casrn)) {
    options$casrn <- casrn
  }
  if (!is.null(chemId)) {
    options$chemId <- chemId
  }
  if (!is.null(cid)) {
    options$cid <- cid
  }
  if (!is.null(image)) {
    options$image <- image
  }
  if (!is.null(inchi)) {
    options$inchi <- inchi
  }
  if (!is.null(inchiKey)) {
    options$inchiKey <- inchiKey
  }
  if (!is.null(mol)) {
    options$mol <- mol
  }
  if (!is.null(molFormula)) {
    options$molFormula <- molFormula
  }
  if (!is.null(monoisotopicMass)) {
    options$monoisotopicMass <- monoisotopicMass
  }
  if (!is.null(name)) {
    options$name <- name
  }
  if (!is.null(sid)) {
    options$sid <- sid
  }
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  result <- generic_chemi_request(
    query = averageMass,
    endpoint = "resolver/safety-flags",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
