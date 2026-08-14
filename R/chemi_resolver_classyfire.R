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
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_classyfire(query = "DTXSID7020182")
#' }
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
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_resolver_classyfire",
    "pre_request",
    list(
      params = list(
        `query` = query,
        `idType` = idType,
        `fuzzy` = fuzzy,
        `kingdom` = kingdom,
        `superklass` = superklass,
        `klass` = klass,
        `subklass` = subklass,
        `directParent` = directParent,
        `geometricDescriptor` = geometricDescriptor,
        `alternativeParent` = alternativeParent,
        `substituent` = substituent,
        `page` = page,
        `size` = size,
        `all_pages` = all_pages,
        `max_pages` = max_pages,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("idType" %in% names(req_data$params)) {
    idType <- req_data$params[["idType"]]
  }
  if ("fuzzy" %in% names(req_data$params)) {
    fuzzy <- req_data$params[["fuzzy"]]
  }
  if ("kingdom" %in% names(req_data$params)) {
    kingdom <- req_data$params[["kingdom"]]
  }
  if ("superklass" %in% names(req_data$params)) {
    superklass <- req_data$params[["superklass"]]
  }
  if ("klass" %in% names(req_data$params)) {
    klass <- req_data$params[["klass"]]
  }
  if ("subklass" %in% names(req_data$params)) {
    subklass <- req_data$params[["subklass"]]
  }
  if ("directParent" %in% names(req_data$params)) {
    directParent <- req_data$params[["directParent"]]
  }
  if ("geometricDescriptor" %in% names(req_data$params)) {
    geometricDescriptor <- req_data$params[["geometricDescriptor"]]
  }
  if ("alternativeParent" %in% names(req_data$params)) {
    alternativeParent <- req_data$params[["alternativeParent"]]
  }
  if ("substituent" %in% names(req_data$params)) {
    substituent <- req_data$params[["substituent"]]
  }
  if ("page" %in% names(req_data$params)) {
    page <- req_data$params[["page"]]
  }
  if ("size" %in% names(req_data$params)) {
    size <- req_data$params[["size"]]
  }
  if ("all_pages" %in% names(req_data$params)) {
    all_pages <- req_data$params[["all_pages"]]
  }
  if ("max_pages" %in% names(req_data$params)) {
    max_pages <- req_data$params[["max_pages"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(query)) {
    options[['query']] <- query
  }
  if (!is.null(idType)) {
    options[['idType']] <- idType
  }
  if (!is.null(fuzzy)) {
    options[['fuzzy']] <- fuzzy
  }
  if (!is.null(kingdom)) {
    options[['kingdom']] <- kingdom
  }
  if (!is.null(superklass)) {
    options[['superklass']] <- superklass
  }
  if (!is.null(klass)) {
    options[['klass']] <- klass
  }
  if (!is.null(subklass)) {
    options[['subklass']] <- subklass
  }
  if (!is.null(directParent)) {
    options[['directParent']] <- directParent
  }
  if (!is.null(geometricDescriptor)) {
    options[['geometricDescriptor']] <- geometricDescriptor
  }
  if (!is.null(alternativeParent)) {
    options[['alternativeParent']] <- alternativeParent
  }
  if (!is.null(substituent)) {
    options[['substituent']] <- substituent
  }
  if (!is.null(page)) {
    options[['page']] <- page
  }
  if (!is.null(size)) {
    options[['size']] <- size
  }
  result <- generic_request(
    endpoint = "resolver/classyfire",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options,
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "page_size"
  )

  # Additional post-processing can be added here

  return(result)
}
