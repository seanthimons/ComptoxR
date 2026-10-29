#' Resolver Lookup
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query query
#' @param idType idType
#' @param fuzzy fuzzy
#' @param mol mol
#' @return Returns a tibble with results
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
      mol = list(default = FALSE, type = "boolean")
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
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/lookup",
    path_params = base::list(),
    query = base::list(
      "query" = params[["query"]],
      "idType" = params[["idType"]],
      "fuzzy" = params[["fuzzy"]],
      "mol" = params[["mol"]]
    ),
    body = NULL,
    response_policy = ".ct_tidy",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    parameter_serialization = list(list(
      name = "mol",
      location = "query",
      schema = list(default = FALSE, type = "boolean"),
      style = "form",
      explode = TRUE,
      collection_format = NULL,
      required = FALSE
    ))
  )
  result
}
