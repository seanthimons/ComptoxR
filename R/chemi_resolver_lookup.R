#' Resolver Lookup
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param fuzzy Optional parameter. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)
#' @param mol Optional parameter (default: FALSE)
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_lookup(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_lookup <- function(query, idType = "AnyId", fuzzy = "Not", mol = FALSE) {
  if (base::is.null(query)) {
    base::stop("Required input: query")
  }
  .api_validation$parameter_values(
    base::list("query" = query, "idType" = idType, "fuzzy" = fuzzy, "mol" = mol),
    list(
      query = list(type = "string", description = "Required parameter"),
      idType = list(
        default = "AnyId",
        enum = list("DTXSID", "DTXCID", "SMILES", "MOL", "CAS", "Name", "InChI", "InChIKey", "InChIKey_1", "AnyId"),
        type = "string",
        description = "Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)"
      ),
      fuzzy = list(
        default = "Not",
        enum = list("Not", "Anywhere", "Start", "Word", "CloseSyntactic", "CloseSemantic"),
        type = "string",
        description = "Optional parameter. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)"
      ),
      mol = list(default = FALSE, type = "boolean", description = "Optional parameter (default: FALSE)")
    ),
    .api_validation$body_value,
    c(query = "query", idType = "query", fuzzy = "query", mol = "query")
  )
  params <- base::list("query" = query, "idType" = idType, "fuzzy" = fuzzy, "mol" = mol)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["idType"]]) && base::any(!base::nzchar(params[["idType"]]))) {
    base::stop("Empty query parameter: idType")
  }
  if (base::is.character(params[["fuzzy"]]) && base::any(!base::nzchar(params[["fuzzy"]]))) {
    base::stop("Empty query parameter: fuzzy")
  }
  if (base::is.character(params[["mol"]]) && base::any(!base::nzchar(params[["mol"]]))) {
    base::stop("Empty query parameter: mol")
  }
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "resolver/lookup",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = TRUE,
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list("idType" = params[["idType"]], "fuzzy" = params[["fuzzy"]], "mol" = params[["mol"]])
      )
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
