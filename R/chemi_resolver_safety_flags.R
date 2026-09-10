#' Resolver Safety Flags
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_safety_flags <- function(query, idType = "AnyId") {
  params <- list("query" = query, "idType" = idType)
  result <- generic_request(
    "endpoint" = "resolver/safety-flags",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("query" = params[["query"]], "idType" = params[["idType"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}

#' Resolver Safety Flags
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param additionalProps Optional parameter
#' @param averageMass Optional parameter
#' @param canonicalSmiles Optional parameter
#' @param casrn Optional parameter
#' @param chemId Optional parameter
#' @param cid Optional parameter
#' @param id Optional parameter
#' @param image Optional parameter
#' @param inchi Optional parameter
#' @param inchiKey Optional parameter
#' @param mol Optional parameter
#' @param molFormula Optional parameter
#' @param monoisotopicMass Optional parameter
#' @param name Optional parameter
#' @param sid Optional parameter
#' @param smiles Optional parameter
#' @param request.filesInfo Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_safety_flags_bulk(additionalProps = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_safety_flags_bulk <- function(
  additionalProps = NULL,
  averageMass = NULL,
  canonicalSmiles = NULL,
  casrn = NULL,
  chemId = NULL,
  cid = NULL,
  id = NULL,
  image = NULL,
  inchi = NULL,
  inchiKey = NULL,
  mol = NULL,
  molFormula = NULL,
  monoisotopicMass = NULL,
  name = NULL,
  sid = NULL,
  smiles = NULL,
  request.filesInfo = NULL
) {
  params <- list(
    "additionalProps" = additionalProps,
    "averageMass" = averageMass,
    "canonicalSmiles" = canonicalSmiles,
    "casrn" = casrn,
    "chemId" = chemId,
    "cid" = cid,
    "id" = id,
    "image" = image,
    "inchi" = inchi,
    "inchiKey" = inchiKey,
    "mol" = mol,
    "molFormula" = molFormula,
    "monoisotopicMass" = monoisotopicMass,
    "name" = name,
    "sid" = sid,
    "smiles" = smiles,
    "request.filesInfo" = request.filesInfo
  )
  result <- generic_chemi_request(
    "query" = params[["additionalProps"]],
    "endpoint" = "resolver/safety-flags",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "averageMass" = params[["averageMass"]],
          "canonicalSmiles" = params[["canonicalSmiles"]],
          "casrn" = params[["casrn"]],
          "chemId" = params[["chemId"]],
          "cid" = params[["cid"]],
          "id" = params[["id"]],
          "image" = params[["image"]],
          "inchi" = params[["inchi"]],
          "inchiKey" = params[["inchiKey"]],
          "mol" = params[["mol"]],
          "molFormula" = params[["molFormula"]],
          "monoisotopicMass" = params[["monoisotopicMass"]],
          "name" = params[["name"]],
          "sid" = params[["sid"]],
          "smiles" = params[["smiles"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
