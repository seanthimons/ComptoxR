#' Resolver Classyfire
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query query
#' @param idType idType
#' @param fuzzy fuzzy
#' @param kingdom kingdom
#' @param superklass superklass
#' @param klass klass
#' @param subklass subklass
#' @param directParent directParent
#' @param geometricDescriptor geometricDescriptor
#' @param alternativeParent alternativeParent
#' @param substituent substituent
#' @param page page
#' @param size size
#' @param all_pages TRUE (the default) requests page after page, starting at page, until a page comes back empty or the client says it was the last or max_pages is reached, and returns the pages combined. FALSE requests only the page given in page.
#' @param max_pages Maximum number of pages requested when all_pages is TRUE. Reaching it stops paging with a warning.
#' @return A list of records.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_classyfire(query = "DTXSID7020182", all_pages = FALSE, max_pages = 2L)
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
  page = 0L,
  size = 1000L,
  all_pages = TRUE,
  max_pages = 100L
) {
  .api_validation$parameter_values(
    base::list(
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
      "size" = size
    ),
    list(
      query = list(type = "string"),
      idType = list(
        default = "AnyId",
        enum = list("DTXSID", "DTXCID", "SMILES", "MOL", "CAS", "Name", "InChI", "InChIKey", "InChIKey_1", "AnyId"),
        type = "string"
      ),
      fuzzy = list(
        default = "Not",
        enum = list("Not", "Anywhere", "Start", "Word", "CloseSyntactic", "CloseSemantic"),
        type = "string"
      ),
      kingdom = list(type = "string"),
      superklass = list(type = "string"),
      klass = list(type = "string"),
      subklass = list(type = "string"),
      directParent = list(type = "string"),
      geometricDescriptor = list(
        type = "string"
      ),
      alternativeParent = list(type = "string"),
      substituent = list(type = "string"),
      page = list(default = 0L, format = "int32", type = "integer"),
      size = list(default = 1000L, format = "int32", type = "integer")
    ),
    .api_validation$body_value,
    c(
      query = "query",
      idType = "query",
      fuzzy = "query",
      kingdom = "query",
      superklass = "query",
      klass = "query",
      subklass = "query",
      directParent = "query",
      geometricDescriptor = "query",
      alternativeParent = "query",
      substituent = "query",
      page = "query",
      size = "query"
    )
  )
  params <- base::list(
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
    "size" = size
  )
  if (!base::is.logical(all_pages) || base::length(all_pages) != 1L || base::is.na(all_pages)) {
    base::stop("all_pages must be TRUE or FALSE", call. = FALSE)
  }
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["idType"]]) && base::any(!base::nzchar(params[["idType"]]))) {
    base::stop("Empty query parameter: idType")
  }
  if (base::is.character(params[["fuzzy"]]) && base::any(!base::nzchar(params[["fuzzy"]]))) {
    base::stop("Empty query parameter: fuzzy")
  }
  if (base::is.character(params[["kingdom"]]) && base::any(!base::nzchar(params[["kingdom"]]))) {
    base::stop("Empty query parameter: kingdom")
  }
  if (base::is.character(params[["superklass"]]) && base::any(!base::nzchar(params[["superklass"]]))) {
    base::stop("Empty query parameter: superklass")
  }
  if (base::is.character(params[["klass"]]) && base::any(!base::nzchar(params[["klass"]]))) {
    base::stop("Empty query parameter: klass")
  }
  if (base::is.character(params[["subklass"]]) && base::any(!base::nzchar(params[["subklass"]]))) {
    base::stop("Empty query parameter: subklass")
  }
  if (base::is.character(params[["directParent"]]) && base::any(!base::nzchar(params[["directParent"]]))) {
    base::stop("Empty query parameter: directParent")
  }
  if (
    base::is.character(params[["geometricDescriptor"]]) && base::any(!base::nzchar(params[["geometricDescriptor"]]))
  ) {
    base::stop("Empty query parameter: geometricDescriptor")
  }
  if (base::is.character(params[["alternativeParent"]]) && base::any(!base::nzchar(params[["alternativeParent"]]))) {
    base::stop("Empty query parameter: alternativeParent")
  }
  if (base::is.character(params[["substituent"]]) && base::any(!base::nzchar(params[["substituent"]]))) {
    base::stop("Empty query parameter: substituent")
  }
  if (base::is.character(params[["page"]]) && base::any(!base::nzchar(params[["page"]]))) {
    base::stop("Empty query parameter: page")
  }
  if (base::is.character(params[["size"]]) && base::any(!base::nzchar(params[["size"]]))) {
    base::stop("Empty query parameter: size")
  }
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/api/resolver/classyfire",
      "path_params" = list(),
      "query" = base::list(
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
      ),
      "body" = NULL,
      "response_policy" = function(response, context, decode) {
        context$endpoint <- "resolver/classyfire"
        if (all_pages) {
          return(.ct_chemi_page(response, context, decode))
        }
        context$query <- "_static_"
        .ct_keyset_manual(response, context, decode)
      },
      "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      "auth" = list(),
      "headers" = list(Accept = "application/json")
    )
    result
  }
  if (!base::isTRUE(all_pages)) {
    base::return(send(params))
  }
  if (base::is.null(params[["page"]])) {
    base::stop("Supply page to start paging, or set all_pages = FALSE", call. = FALSE)
  }
  result <- .ct_request_pages(
    function(page) {
      params[base::names(page)] <- page
      send(params)
    },
    "page",
    params[["page"]],
    max_pages,
    completed = base::get(
      ".ct_chemi_done",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    mode = "page",
    next_cursor = NULL,
    items = NULL,
    error_policy = "partial",
    warn_limits = TRUE,
    warn_errors = FALSE,
    stop_on_empty = FALSE,
    on_limit = base::get(
      ".ct_keyset_limit_warning",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    )
  )
  if (!base::inherits(result, "httr2_request") && !base::is.null(result)) {
    base::attr(result, "pagination") <- NULL
  }
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  kept <- base::attr(result, "pagination", exact = TRUE)
  result <- run_hook("chemi_resolver_classyfire", "post_combine", base::list(result = result, params = params))
  if (!base::is.null(kept) && !base::is.null(result) && base::is.null(base::attr(result, "pagination", exact = TRUE))) {
    base::attr(result, "pagination") <- kept
  }
  result
}
