#' Resolver Classyfire
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param fuzzy Optional parameter. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)
#' @param kingdom Optional parameter
#' @param superklass Optional parameter
#' @param klass Optional parameter
#' @param subklass Optional parameter
#' @param directParent Optional parameter
#' @param geometricDescriptor Optional parameter
#' @param alternativeParent Optional parameter
#' @param substituent Optional parameter
#' @param page Optional parameter (default: 0)
#' @param size Optional parameter (default: 1000)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_classyfire(query = "DTXSID7020182")
#' }
chemi_resolver_classyfire <- function(query, idType = "AnyId", fuzzy = "Not", kingdom = NULL, superklass = NULL, klass = NULL, subklass = NULL, directParent = NULL, geometricDescriptor = NULL, alternativeParent = NULL, substituent = NULL, page = 0, size = 1000) {
  generic_request(
    endpoint = "resolver/classyfire",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    query = query,
    idType = idType,
    fuzzy = fuzzy,
    kingdom = kingdom,
    superklass = superklass,
    klass = klass,
    subklass = subklass,
    directParent = directParent,
    geometricDescriptor = geometricDescriptor,
    alternativeParent = alternativeParent,
    substituent = substituent,
    page = page,
    size = size
  )
}


