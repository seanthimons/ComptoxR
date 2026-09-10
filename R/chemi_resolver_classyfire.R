#' Resolver Classyfire
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
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
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_classyfire(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_classyfire <- function(
  query = NULL,
  idType = "AnyId",
  fuzzy = "Not",
  kingdom = NULL,
  superklass = NULL,
  klass = NULL,
  subklass = NULL,
  directParent = NULL,
  geometricDescriptor = NULL,
  alternativeParent = NULL,
  substituent = NULL,
  page = 0,
  size = 1000,
  all_pages = TRUE,
  max_pages = 100
) {
  params <- list(
    "query" = query,
    "idType" = idType,
    "fuzzy" = fuzzy,
    "kingdom" = kingdom,
    "superklass" = superklass,
    "klass" = klass,
    "subklass" = subklass,
    "directParent" = directParent,
    "geometricDescriptor" = geometricDescriptor,
    "alternativeParent" = alternativeParent,
    "substituent" = substituent,
    "page" = page,
    "size" = size,
    "all_pages" = all_pages,
    "max_pages" = max_pages
  )
  result <- generic_request(
    "endpoint" = "resolver/classyfire",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "query" = params[["query"]],
          "idType" = params[["idType"]],
          "fuzzy" = params[["fuzzy"]],
          "kingdom" = params[["kingdom"]],
          "superklass" = params[["superklass"]],
          "klass" = params[["klass"]],
          "subklass" = params[["subklass"]],
          "directParent" = params[["directParent"]],
          "geometricDescriptor" = params[["geometricDescriptor"]],
          "alternativeParent" = params[["alternativeParent"]],
          "substituent" = params[["substituent"]],
          "page" = params[["page"]],
          "size" = params[["size"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "page_size"
  )
  result
}
