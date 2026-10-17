#' Resolver Mesh
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query query
#' @param idType idType
#' @param fuzzy fuzzy
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_mesh(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_mesh <- function(query, idType = "AnyId", fuzzy = "Not") {
  if (base::is.null(query)) {
    base::stop("Required input: query")
  }
  .api_validation$parameter_values(
    base::list("query" = query, "idType" = idType, "fuzzy" = fuzzy),
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
      )
    ),
    .api_validation$body_value,
    c(query = "query", idType = "query", fuzzy = "query")
  )
  params <- base::list("query" = query, "idType" = idType, "fuzzy" = fuzzy)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["idType"]]) && base::any(!base::nzchar(params[["idType"]]))) {
    base::stop("Empty query parameter: idType")
  }
  if (base::is.character(params[["fuzzy"]]) && base::any(!base::nzchar(params[["fuzzy"]]))) {
    base::stop("Empty query parameter: fuzzy")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/resolver/mesh",
    path_params = base::list(),
    query = base::list("query" = params[["query"]], "idType" = params[["idType"]], "fuzzy" = params[["fuzzy"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
