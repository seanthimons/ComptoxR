#' Resolver Lookup (Bulk)
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Performs bulk lookup of chemical identifiers via POST endpoint.
#' @param ids Character vector of chemical identifiers to look up. All identifiers must be of the same type or type should be AnyId.
#' @param idsType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param fuzzy Fuzzy lookup setting. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)
#' @param mol If TRUE, MOL is requested as a result (default: FALSE)
#' @param filters Optional filters object
#' @param format Optional format specification. Options: UNKNOWN, SDF, SMI, MOL, CSV, TSV, JSON, XLSX, PDF, HTML, XML, DOCX
#' @param tidy Logical; if TRUE (default), return a tibble. If FALSE, return a cleaned list.
#' @return A tibble when tidy is TRUE, otherwise the decoded JSON response.
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_lookup_bulk(ids = c("DTXSID7020182", "50-00-0"))
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_lookup_bulk <- function(
  ids,
  idsType = "AnyId",
  fuzzy = "Not",
  mol = FALSE,
  filters = NULL,
  format = NULL,
  tidy = TRUE
) {
  ids <- base::get(".ct_lookup_ids", envir = base::parent.env(base::environment()), mode = "function", inherits = TRUE)(
    ids
  )
  params <- base::list(
    "ids" = ids,
    "idsType" = idsType,
    "fuzzy" = fuzzy,
    "mol" = mol,
    "filters" = filters,
    "format" = format,
    "tidy" = function() tidy
  )
  state <- run_hook("chemi_resolver_lookup_bulk", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/resolver/lookup",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = .ct_lookup_body(params),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$query <- params[["ids"]]
      context$endpoint <- "resolver/lookup"
      .ct_chemi_result(response, context, decode, tidy = params[["tidy"]]())
    }
  )
  result
}
