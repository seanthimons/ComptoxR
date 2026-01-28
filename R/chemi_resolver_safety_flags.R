#' Resolver Safety Flags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags(query = "DTXSID7020182")
#' }
chemi_resolver_safety_flags <- function(query, idType = "AnyId") {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(idType)) options[['idType']] <- idType
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
#' @param chemId Optional parameter
#' @param cid Optional parameter
#' @param sid Optional parameter
#' @param casrn Optional parameter
#' @param name Optional parameter
#' @param smiles Optional parameter
#' @param canonicalSmiles Optional parameter
#' @param inchi Optional parameter
#' @param inchiKey Optional parameter
#' @param mol Optional parameter
#' @param molFormula Optional parameter
#' @param averageMass Optional parameter
#' @param monoisotopicMass Optional parameter
#' @param image Optional parameter
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags_bulk(chemId = c("DTXSID60897236", "DTXSID6020692", "DTXSID901336502"))
#' }
chemi_resolver_safety_flags_bulk <- function(chemId = NULL, cid = NULL, sid = NULL, casrn = NULL, name = NULL, smiles = NULL, canonicalSmiles = NULL, inchi = NULL, inchiKey = NULL, mol = NULL, molFormula = NULL, averageMass = NULL, monoisotopicMass = NULL, image = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(cid)) options$cid <- cid
  if (!is.null(sid)) options$sid <- sid
  if (!is.null(casrn)) options$casrn <- casrn
  if (!is.null(name)) options$name <- name
  if (!is.null(smiles)) options$smiles <- smiles
  if (!is.null(canonicalSmiles)) options$canonicalSmiles <- canonicalSmiles
  if (!is.null(inchi)) options$inchi <- inchi
  if (!is.null(inchiKey)) options$inchiKey <- inchiKey
  if (!is.null(mol)) options$mol <- mol
  if (!is.null(molFormula)) options$molFormula <- molFormula
  if (!is.null(averageMass)) options$averageMass <- averageMass
  if (!is.null(monoisotopicMass)) options$monoisotopicMass <- monoisotopicMass
  if (!is.null(image)) options$image <- image
  result <- generic_chemi_request(
    query = chemId,
    endpoint = "resolver/safety-flags",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


