#' Resolver Classyfire
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Optional parameter
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
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_classyfire(query = "DTXSID7020182")
#' }
chemi_resolver_classyfire <- function(query = NULL, idType = "AnyId", fuzzy = "Not", kingdom = NULL, superklass = NULL, klass = NULL, subklass = NULL, directParent = NULL, geometricDescriptor = NULL, alternativeParent = NULL, substituent = NULL, page = 0, size = 1000) {
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(idType)) options[['idType']] <- idType
  if (!is.null(fuzzy)) options[['fuzzy']] <- fuzzy
  if (!is.null(kingdom)) options[['kingdom']] <- kingdom
  if (!is.null(superklass)) options[['superklass']] <- superklass
  if (!is.null(klass)) options[['klass']] <- klass
  if (!is.null(subklass)) options[['subklass']] <- subklass
  if (!is.null(directParent)) options[['directParent']] <- directParent
  if (!is.null(geometricDescriptor)) options[['geometricDescriptor']] <- geometricDescriptor
  if (!is.null(alternativeParent)) options[['alternativeParent']] <- alternativeParent
  if (!is.null(substituent)) options[['substituent']] <- substituent
  if (!is.null(page)) options[['page']] <- page
  if (!is.null(size)) options[['size']] <- size
    result <- generic_request(
    endpoint = "resolver/classyfire",
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


