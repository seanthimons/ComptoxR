#' 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param idType Optional parameter
#' @param fuzzy Optional parameter
#' @param kingdom Optional parameter
#' @param superklass Optional parameter
#' @param klass Optional parameter
#' @param subklass Optional parameter
#' @param directParent Optional parameter
#' @param geometricDescriptor Optional parameter
#' @param alternativeParent Optional parameter
#' @param substituent Optional parameter
#' @param page Optional parameter
#' @param size Optional parameter

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_resolver_classyfire(query = "DTXSID7020182")
#' }
chemi_resolver_resolver_classyfire <- function(query, idType = NULL, fuzzy = NULL, kingdom = NULL, superklass = NULL, klass = NULL, subklass = NULL, directParent = NULL, geometricDescriptor = NULL, alternativeParent = NULL, substituent = NULL, page = NULL, size = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(idType)) options$idType <- idType
  if (!is.null(fuzzy)) options$fuzzy <- fuzzy
  if (!is.null(kingdom)) options$kingdom <- kingdom
  if (!is.null(superklass)) options$superklass <- superklass
  if (!is.null(klass)) options$klass <- klass
  if (!is.null(subklass)) options$subklass <- subklass
  if (!is.null(directParent)) options$directParent <- directParent
  if (!is.null(geometricDescriptor)) options$geometricDescriptor <- geometricDescriptor
  if (!is.null(alternativeParent)) options$alternativeParent <- alternativeParent
  if (!is.null(substituent)) options$substituent <- substituent
  if (!is.null(page)) options$page <- page
  if (!is.null(size)) options$size <- size

  generic_chemi_request(
    query = query,
    endpoint = "api/resolver/classyfire",
    server = "chemi_burl",
    auth = FALSE,
    options = options
  )
}